(ns tichy.core
  (:require [xmpp-clj :as xmpp]))

(defonce brain (atom {:name "Ijon Tichy"}))

(def ears (fn [m]
            (loop [hooks @ear-hook]
              (when (first hooks)
                (if-let [r (try
                             ((first  hooks) m)
                             (catch Exception e
                               (println "ERROR: e")))]
                  r
                  (recur (rest hooks)))))))

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


(defonce voice (atom 
                (fn [m]
                  m)))

(defn remember [k v]
  (swap! brain assoc k v))

(defn forget [k v]
  (swap! brain dissoc k))

(defn live [config]
  (let [myconfig 
        {:name  (or (:name config)
                    (:name brain)
                    "Ijon Tichy")
         :username (:username config)
         :password (:password config)
         :host (:host config)
         :domain (:domain config)
         :handler (fn [m] 
                    (when-let [response (ears m)]
                      (@voice response)))}]
    (remember :config myconfig)
    (apply xmpp/start-bot 
           (flatten (seq (:config @brain))))))

(defn die [config]
  (xmpp/stop-bot (or (:name config) (:name brain) "Ijon Tichy")))


