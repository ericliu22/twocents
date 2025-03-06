package message

import (
	"log"
	"net/http"
	"github.com/gorilla/websocket"
)

type Client struct {
    hub  *Hub
    conn *websocket.Conn
    send chan []byte
}

// readPump will read messages from the WebSocket (client->server). 
// For notifications only, you might not do much here, but you can handle pings or commands.
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
        // If you need to handle client messages, do so here
        log.Printf("Received message from client: %s", message)
    }
}

// writePump writes messages from the Hub -> the client
func (client *Client) writePump() {
    defer client.conn.Close()

    for {
        select {
        case msg, ok := <-client.send:
            if !ok {
                // Channel closed -> hub unregistered us
                log.Println("Hub closed the channel")
                return
            }
            err := client.conn.WriteMessage(websocket.TextMessage, msg)
            if err != nil {
                log.Println("Write error:", err)
                return
            }
        }
    }
}

// ServeWS upgrades the HTTP connection to a WebSocket, registers the client with the hub
func ServeWS(hub *Hub, w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("Error upgrading to websocket:", err)
        return
    }
    client := &Client{
        hub:  hub,
        conn: conn,
        send: make(chan []byte, 256),
    }

    // Register client in the hub
    client.hub.register <- client

    // Start goroutines for readPump/writePump
    go client.writePump()
    go client.readPump()
}
