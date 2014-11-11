(in-package :cl-user)

(declaim (optimize (speed 3)))

(defvar *lisp-listener* nil)

(defstruct dg-node
  (weight 0)
  label
  (terminus nil)
  (edges-from (make-hash-table :size 10 :test 'equal))
  (edges-to (make-hash-table :size 10 :test 'equal)))

(defstruct dg-edge
  (weight 0)
  source
  target)

(defvar *dg-start* (make-dg-node :label "start"))

(defvar *dg-hash* (make-hash-table :test 'equal))

(defun clear-brain ()
  (clrhash *dg-hash*)
  (setf *dg-start*  (make-dg-node :label "start")))

(defun load-brain (&aux (ctr 0))
  (clear-brain)
  (with-open-file
   (stream "/home/opus/boot" :direction :input)
   (handler-case
    (loop
      (add-utterance (read-line stream))
      (incf ctr)
      (when (= 0 (mod ctr 1000))
	(format t "~& line = ~d~%" ctr)))
    (error ()
	   (format t "done")))))

(defun load-gibbon (&aux (ctr 0))
  (clear-brain)
  (with-open-file
   (stream "/home/opus/gibbon" :direction :input)
   (handler-case
    (loop
      (add-utterance (read-line stream))
      (incf ctr)
      (when (= 0 (mod ctr 1000))
	(format t "~& line = ~d~%" ctr)))
    (error ()
	   (format t "done")))))

(defun load-shit (shit &aux (ctr 0))
  (with-open-file
   (stream shit :direction :input)
   (handler-case
    (loop
      (add-utterance (read-line stream))
      (incf ctr)
      (when (= 0 (mod ctr 1000))
	(format t "~& line = ~d~%" ctr)))
    (error ()
	   (format t "done")))))



(defun add-utterance (utterance)
  (let ((putter (tokenize utterance)))
    (impart-utterance putter *dg-start*)))

(defun impart-utterance (utter node)
  (incf (dg-node-weight node))
  (if utter
      (let ((next-node-label (car utter))
	    (next-edge nil))
	(setf next-edge (gethash next-node-label (dg-node-edges-to node)))
	(if (not next-edge)
	    (let ((tgt-node (or (gethash next-node-label *dg-hash*)
				(setf (gethash next-node-label *dg-hash*)
				      (make-dg-node :label next-node-label)))))
	      (setf next-edge (make-dg-edge :source node
					    :target tgt-node))
	      (setf (gethash (dg-node-label node) (dg-node-edges-from tgt-node))
		    next-edge)
	      (setf (gethash next-node-label (dg-node-edges-to node))
		    next-edge)))
	(progn
	  (incf (dg-edge-weight next-edge))
	  (impart-utterance (cdr utter) (dg-edge-target next-edge))))
    (setf (dg-node-terminus node) t)))

(defun reply (utterance &aux interest)
   (let ((putter (tokenize utterance))) 
     (dolist (putter-elt putter)
       (when (< 3 (length putter-elt))
	 (let ((node (gethash putter-elt *dg-hash*)))
	   ;;(if node
	   ;;    (setf node (select-edge node)))
	   (if node
	       (push node interest)))))
     (format t ":: interesting = ~s~%" interest)
     (if interest
	 (let ((start-forward (Car interest))
	       (start-backward (car interest))
	       (reply (list (car interest))))
	   (loop
	    (let ((next-node (select-edge start-forward)))
	      (if (null next-node)
		  (return))
	      (push next-node reply)
	      (setf start-forward next-node)
	      (if (and (< 3 (random 8))
		       (dg-node-terminus next-node))
		  (return))))
	   (setf reply (nreverse reply))

	   (format t ";; Completion = ~s~%" reply)

	   (loop
	    (let ((next-node (select-edge start-backward t)))
	      (if (or (null next-node)
		      (eql next-node start-backward)
		      (eql next-node *dg-start*))
		  (return))
	      (push next-node reply)
	      (setf start-backward next-node)))

	   (format nil "~{~a~^ ~}" (mapcar #'dg-node-label reply))))))

	   
	   

     
;     (loop
;      (let ((reply nil)
;	    (node *dg-start*))
;	(loop
;	 (let ((next-node (select-edge node)))
;	   (if (or (null next-node)
;		   (< 10 (length reply)))
;	       (return reply))
;	   (push next-node reply)
;	   (setf node next-node)))
;	;; (impart-utterance putter *dg-start*)
;	(cond ((intersection interest reply)
;	       (return-from reply
;	      ((< 10 count)
;	       (Return-from reply
;			    (format nil "~{~a~^ ~}" (nreverse (mapcar #'dg-node-label reply)))))
;	      (t
	;       (incf count)))))))

(defun get-node-edges (node &optional back &aux edges)
  (maphash (lambda (k v)
	     (push v edges)) (if back
				 (dg-node-edges-from node)
			       (dg-node-edges-to node)))
  edges)

(defun select-edge (node &optional back)
  (let* ((edges (get-node-edges node back))
	 (total-weight (apply #'+ (mapcar #'dg-edge-weight edges))))
    (if (< 0 total-weight)
	(let ((edge-selected (random total-weight)))
	  (dolist (edge edges)
	    (decf edge-selected (dg-edge-weight edge))
	    (if (<= edge-selected 1)
		(return-from select-edge (if back
					     (dg-edge-source edge)
					   (dg-edge-target edge)))))))))

(defun tokenize (string)
  (let (out buf)
    (dotimes (x (length string))
      (if (not (char= #\space (aref string x)))
	  (push (aref string x) buf)
	(if buf
	    (progn
	      (push (chars-to-sym (nreverse buf)) out)
	      (setf buf nil)))))
    (if buf
	(push (chars-to-sym (nreverse buf)) out))
    (nreverse out)))

(defun chars-to-sym (chars)
  (let ((string (make-string (length chars))))
    (dotimes (idx  (length chars))
      (setf (aref string idx)
	    (char-downcase (nth idx chars))))
    string))
	      
(defun cgi-process (fd)
  (lambda ()
    (let ((stream (sys:make-fd-stream fd :input t :output t)))
      (unwind-protect
	  (let* ((input (read-line stream))
		 (output (reply input)))
	    (format t "<== ~a~%" input)
	    (format t "==> ~a~%" output)
	    (if output
		(format stream "~a~%" output))
	    (terpri stream))
        (close stream)))))

(defun cgi-listener ()
  "this function runs in a thread for the lifetime of the server
process, listening on the imho port and spawning client socket
connections."
  (let (socket host retries)
    (loop
     (mp::process-wait-until-fd-usable *lisp-listener* :input)
     (setq retries 0)
     (handler-case
         (multiple-value-setq
             (socket host)
           (ext:accept-tcp-connection *lisp-listener*))
       (error ()
         (setq socket nil)
         (if (= retries 5)
             nil
             (progn
               (incf retries)
               (sleep 5)))))
     (when socket
       (mp::make-process (cgi-process socket)
                     :name "vs")
       (setq retries 0)))))

(defvar *lisp-server* nil)

(defun monty ()
  (sys:ignore-interrupt unix:sigpipe)
  (unless *lisp-listener*
    (setf *lisp-listener* (ext:create-inet-listener 14303)))
  (setf *lisp-server*
	(mp::make-process (lambda ()
			(cgi-listener))
		      :name "Monty")))



(defun tweak ()
  (dolist (term '("or" "even" "and" "all" "of" "to" "the" "with" "who" "from" "in" "at" "but" "we"))
    (setf (dg-node-terminus (gethash term *dg-hash*)) nil)))