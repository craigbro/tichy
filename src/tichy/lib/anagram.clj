(ns tichy.lib.anagram
  (:require [clojure.java.io :refer [reader]]
            [clojure.string :refer [join]]
            [clojure.math.combinatorics :refer [subsets]]))

(def lexicon (atom {}))

(defrecord Word [text histogram])

(defn empty-word? [word]
  (not (some #(< 0 %) (:histogram word))))

(defn histogram->string [h]
  (->> (map (fn [letter-count letter-index]
              (take letter-count
                    (repeat (char (+ 65 letter-index)))))
            h
            (range (count h)))
       (conc-vals)
       (join)))

(defn subtract-word [w sw]
  (let [diff (map - (:histogram w) (:histogram sw))]
    (when-not (some #(< % 0) diff)
      (Word. (histogram->string diff) diff))))

(defn word-factory [s]
  (let [freq (int-array 26)]
    (doseq [c (.toUpperCase s)]
      (let [c2 (- (int c) 65)]
        (when (<= 0 c2 25)
          (aset freq c2 (+ (aget freq c2) 1)))))
    (Word. s (vec freq))))

(defn conc-vals [s]
  (apply concat (filter #(not (empty? %)) s)))

(defn trie-path [w]
  (->> (map (fn [letter-count letter-index]
              (take (if (= 0 letter-count)
                      0 1)
                    (repeat (char (+ 65 letter-index)))))
            (:histogram w)
            (range (count (:histogram w))))
       (conc-vals)))

(defn build-trie [s]
  (loop [trie {} s s]
    (cond (empty? (first s))
          trie
          (< (count word) 4)
          (recur trie (rest s))
          true
          (let [word (word-factory (first s))
                path (trie-path word)]
            (let [existing-value (get-in trie path)
                  new-value (merge existing-value
                                   {:val (cons word (get existing-value :val))
                                    :terminal true})]
              (recur (assoc-in trie path new-value)
                     (rest s)))))))

(defn load-lexicon []
  (with-open [r (reader "/usr/share/dict/words")]
    (swap! lexicon (fn [_] (build-trie (line-seq r)))))
  true)

(defn anagram-candidates [lexicon w]
  (conc-vals
   (map (fn [prefix]
          (:val (get-in lexicon prefix)))
        (subsets (trie-path w)))))

(defn %anagrams [w]
  (->> (anagram-candidates @lexicon w)
       (map (fn [candidate]
              (when-let [remainder (subtract-word w candidate)]
                (if (empty-word? remainder)
                  (list (list candidate))
                  (map #(cons candidate %)
                       (%anagrams remainder))))))
       (apply concat)))

(defn anagram [s]
  (first (map (fn [a]                   ; but first is not the funniest: optimize
                (map #(:text %) a))
              (%anagrams (word-factory s)))))
