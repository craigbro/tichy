(ns tichy.core
  (:require [tichy.lib.xmpp :as xmpp]))

(defonce brain (atom {:name "Ijon Tichy"}))

(defonce ear-hook (atom []))

(defn clear-ear-hook []
  (reset! ear-hook []))

(defn add-ear-hook [func]
  (do
    (when-not
        (some #{func} @ear-hook)
      (swap! ear-hook conj func))
    @ear-hook))

(defn remove-ear-hook [func]
  (swap! ear-hook
         (partial
          remove #{func})))

(def ears (fn [m]
            (loop [hooks @ear-hook]
              (when (first hooks)
                (if-let [r (try
                             ((first  hooks) m)
                             (catch Exception e
                               (println "ERROR: e")))]
                  r
                  (recur (rest hooks)))))))

(defonce voice (atom
                (fn [m]
                  m)))

(defn remember [k v]
  (swap! brain assoc k v))

(defn forget [k v]
  (swap! brain dissoc k))

(defn tichy-handler [message]
  (when-let [response (ears message)]
    (@voice response)))

(defonce config (atom {:username "tichy"
                       :password "doot"
                       :host "localhost"
                       :domain "localhost"}))

(defn stopped->started [brain]
  (let [connection (xmpp/connection-factory @config)]
    (xmpp/add-handler! connection tichy-handler)
    (merge brain {:state :running
                  :connection connection})))

(defn started->stopped [brain]
  (.disconnect (:connection brain))
  (-> brain
      (dissoc :connection)
      (assoc :state :stopped)))

(defn start []
  (swap! brain stopped->started))

(defn stop []
  (swap! brain started->stopped))

;; (start)
;; (stop)
