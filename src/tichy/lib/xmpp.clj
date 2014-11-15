(ns tichy.lib.xmpp
  (:import [org.jivesoftware.smack ConnectionConfiguration XMPPConnection
            XMPPException PacketListener]
           [org.jivesoftware.smack.packet Message Presence Presence$Type
            Message$Type]
           [org.jivesoftware.smack.filter MessageTypeFilter]
           [org.jivesoftware.smack.util StringUtils]))

(defn message->map [#^Message message]
  {:body      (.getBody message)
   :subject   (.getSubject message)
   :thread    (.getThread message)
   :from      (.getFrom message)
   :from-name (StringUtils/parseBareAddress (.getFrom message))
   :to        (.getTo message)
   :packet-id (.getPacketID message)
   :error     (when-let [error (.getError message)]
                {:code    (.getCode error)
                 :message (.getMessage error)})
   :type      (keyword (str (.getType message)))})

(defn connection-factory
  [{:keys [username password host domain port] :or {port 5222}}]
  (doto (-> (ConnectionConfiguration. host port domain)
            (XMPPConnection.))
    (.connect)
    (.login username password)
    (.sendPacket (Presence. Presence$Type/available))))

(defn reply [from-message to-message-body connection]
  (->> (doto (Message. (:from-name from-message) (Message$Type/chat))
         (.setBody (str to-message-body)))
       (.sendPacket connection)))

(defn handler->processor [handler]
  (fn [connection message]
    (let [message (message->map message)]
      (reply message (handler message) connection))))

(defn processor->listener [connection processor]
  (proxy [PacketListener] []
    (processPacket [packet]
      (processor connection packet))))

(defn add-handler! [connection handler]
  (.addPacketListener connection
                      (->> (handler->processor handler)
                           (processor->listener connection))
                      (MessageTypeFilter. Message$Type/chat)))
