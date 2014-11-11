(ns tichy.core-test
  (:use tichy.core
        clojure.test))


(defn clear-state [f]
  (clear-ear-hook)
  (swap! brain {})
  (f))

(use-fixtures :each clear-state)


(deftest test-base
  (clear-ear-hook)
  (swap! brain {})
  (add-ear-hook (fn [m] nil))
  (add-ear-hook :body)
  (is (= "foo" (ears {:body "foo"}))
      "Ear handlers are run")
  (remove-ear-hook :body)
  (is (not (= "foo" (ears {:body "foo"})))
      "Ear handlers are removed")
  ;; add this one back
  (add-ear-hook :body)
  ;; then this one will be first in the handler list
  (add-ear-hook (fn [m] (clojure.string/upper-case (:body m))))
  (is (= "FOO" (ears {:body "foo"}))
      "Ear handlers stop at first handler that returns a result"))


