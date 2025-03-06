package message

import (
    "sync"
)


// Hub manages all WebSocket clients and broadcasts messages to them.
type Hub struct {
    // Registered clients
    clients map[*Client]bool

    // Channel for broadcast messages
    broadcast chan []byte

    // Register requests from clients
    register chan *Client

    // Unregister requests from clients
    unregister chan *Client

    // A mutex to protect the clients map if needed
    mutex sync.RWMutex
}

func NewHub() *Hub {
    return &Hub{
        clients:    make(map[*Client]bool),
        broadcast:  make(chan []byte),
        register:   make(chan *Client),
        unregister: make(chan *Client),
    }
}

// Run starts the event loop for the hub
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

        case message := <-hub.broadcast:
            // Send the message to every client
            hub.mutex.RLock()
            for client := range hub.clients {
                select {
                case client.send <- message:
                default:
                    // If the client can't receive, consider closing
                    close(client.send)
                    delete(hub.clients, client)
                }
            }
            hub.mutex.RUnlock()
        }
    }
}

// Broadcast allows external code (e.g., RabbitMQ consumer) to send data to all WS clients
func (hub *Hub) Broadcast(msg []byte) {
    hub.broadcast <- msg
}

// For debugging
func (hub *Hub) NumClients() int {
    hub.mutex.RLock()
    defer hub.mutex.RUnlock()
    return len(hub.clients)
}

