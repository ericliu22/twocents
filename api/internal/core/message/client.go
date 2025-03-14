package message

import (
	"log"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

// Client represents a single WebSocket connection.
// The ID field uniquely identifies the end-user connection.
type Client struct {
	hub    *Hub
	conn   *websocket.Conn
	send   chan []byte
	ID     uuid.UUID // Unique identifier for the WS client (end-user)
	Groups []uuid.UUID
}

// readPump reads messages from the WebSocket connection.
// For notifications, this might only be used for pings or minimal commands.
func (client *Client) readPump() {
	defer func() {
		client.hub.unregister <- client
		client.conn.Close()
	}()

	for {
		_, message, err := client.conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			break
		}
		log.Printf("Received message from client %s: %s", client.ID, message)
	}
}

// writePump writes messages from the hub to the WebSocket connection.
func (client *Client) writePump() {
	defer client.conn.Close()

	for {
		select {
		case msg, ok := <-client.send:
			if !ok {
				log.Println("Hub closed the channel for client", client.ID)
				return
			}
			err := client.conn.WriteMessage(websocket.TextMessage, msg)
			if err != nil {
				log.Println("Write error for client", client.ID, ":", err)
				return
			}
		}
	}
}

// ServeWS upgrades the HTTP connection to a WebSocket and registers the client with the Hub.
// The clientID parameter sets the client's identifier for targeted messaging.
func ServeWS(hub *Hub, writer http.ResponseWriter, requests *http.Request, clientID uuid.UUID, groups []uuid.UUID) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		// Allow all connections for demonstration purposes.
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	conn, err := upgrader.Upgrade(writer, requests, nil)
	if err != nil {
		log.Println("Error upgrading to websocket:", err)
		return
	}
	client := &Client{
		hub:  hub,
		conn: conn,
		send: make(chan []byte, 256),
		ID:   clientID,
	}

	// Register the client with the hub.
	client.hub.register <- client

	// Start the read and write pumps.
	go client.writePump()
	go client.readPump()
}
