package message

import (
	"sync"

	"github.com/google/uuid"
)

// WSMessage is a message to be sent via websockets.
// If Target is non-empty, the message should only go to that client.
type WSMessage struct {
	Target *uuid.UUID `json:"target"` // ID of the target WS client (end-user)
	Group  *uuid.UUID `json:"group"` // ID of the group of WS clients
	Data   []byte `json:"data"`   // The payload to be sent
}

type Hub struct {
	// Registered clients.
	clients map[*Client]bool

	// Channel for messages to be broadcast.
	broadcast chan WSMessage

	// Register requests from clients.
	register chan *Client

	// Unregister requests from clients.
	unregister chan *Client

	// Mutex to protect the clients map.
	mutex sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		broadcast:  make(chan WSMessage),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

func (hub *Hub) Run() {
	for {
		select {
		case client := <-hub.register:
			hub.mutex.Lock()
			hub.clients[client] = true
			hub.mutex.Unlock()

		case client := <-hub.unregister:
			hub.mutex.Lock()
			if _, ok := hub.clients[client]; ok {
				delete(hub.clients, client)
				close(client.send)
			}
			hub.mutex.Unlock()

		case msg := <-hub.broadcast:
			if msg.Target != nil {
				// Send only to the client(s) with a matching ID.
				hub.mutex.RLock()
				for client := range hub.clients {
					if client.ID == msg.Target {
						select {
						case client.send <- msg.Data:
						default:
							// If the client can’t receive the message, close the connection.
							close(client.send)
							delete(hub.clients, client)
						}
					}
				}
				hub.mutex.RUnlock()
			} else {
				// Broadcast to all clients.
				hub.mutex.RLock()
				for client := range hub.clients {
					select {
					case client.send <- msg.Data:
					default:
						close(client.send)
						delete(hub.clients, client)
					}
				}
				hub.mutex.RUnlock()
			}
		}
	}
}

// Broadcast pushes a WSMessage into the hub's broadcast channel.
func (hub *Hub) Broadcast(msg WSMessage) {
	hub.broadcast <- msg
}

// NumClients returns the number of currently connected clients.
func (hub *Hub) NumClients() int {
	hub.mutex.RLock()
	defer hub.mutex.RUnlock()
	return len(hub.clients)
}
