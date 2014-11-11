(defun find-first-unescaped-char (string char escape start)
  (if (= start (length string)) nil
      (let ((position (position char string :start start :test #'char=)))
        (when position
          (cond ((= position start) start)
                ((and escape (char= (elt string (- position 1)) escape))
                 (find-first-unescaped-char string char escape (1+ position)))
                (t position))))))

(defun split (string delim &key preserve-empty-strings escape (start 0) max-results)
  (if (or (= start (length string)) (and max-results (< max-results 0)))
      nil
      (let ((position (find-first-unescaped-char string delim escape start)))
        (if position
            (if (= position start)
                (if preserve-empty-strings
                    (cons ""
                          (split string delim
                                 :preserve-empty-strings preserve-empty-strings
                                 :max-results (if (null max-results) nil
                                                  (- max-results 1))
                                 :escape escape :start (+ position 1)))
                    (split string delim
                           :preserve-empty-strings preserve-empty-strings
                           :max-results (if (null max-results) nil
                                            (- max-results 1))
                           :escape escape :start (+ position 1)))
                (cons (subseq string start position)
                      (split string delim
                             :preserve-empty-strings preserve-empty-strings
                             :max-results (if (null max-results) nil
                                              (- max-results 1))
                             :escape escape :start (+ position 1))))
            (list (subseq string start (length string)))))))

(defun make-nasty-hash ()
  (let ((hash (make-hash-table :test #'equal))
        (counter 0))
    (with-open-file (stream "/home/opus/slang" :direction :input)
      (handler-case
          (loop
           (setf (gethash (read-line stream) hash) (incf counter)))
        (error ()
          )))
    hash))

(defun score-anagram (hash orig anagram)
  (let ((score 0))
;    (unless (equal orig anagram)
;      (incf score (* 100 (- 10 (length anagram)))))
    (dotimes (x (length anagram))
      (when (gethash (nth x anagram) hash)
        (incf score 560)))
    score))

(defun nastygram (string)
  (let ((output nil)
        (orig (split string #\Space))
        (hash (make-nasty-hash))
        (proc (sb-ext:run-program "/usr/games/an" (list "-d" "/home/opus/opusdict" string) :output :stream
				  :wait nil)))
    (unwind-protect
         (handler-case
             (dotimes (x 5000)
               (let ((anagram (split (read-line (process-output proc)) #\Space)))
                 (push (cons (score-anagram hash orig anagram) anagram) output)))
           (error ()
             ))
      (process-kill proc 11))
    (format t "~{~a~^ ~}~%" (cdar (sort output #'> :key #'car)))))
