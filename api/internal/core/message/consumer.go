package message

import (
	"log"

	"github.com/IBM/sarama"
)

func SetupKafkaConsumer(hub *Hub) {
	// Set up Sarama consumer configuration.
	config := sarama.NewConfig()
	config.Consumer.Return.Errors = true

	// List of Kafka broker addresses.
	brokers := []string{"broker:9092"}
	// The topic to consume post events from.

	// Create a new consumer.
	consumer, err := sarama.NewConsumer(brokers, config)
	if err != nil {
		log.Fatal("Error creating kafka consumer" + err.Error())
		return
	}

	setupPostsConsumer(consumer, hub)
	// For demonstration, we consume from partition 0 starting at the newest offset.
}

func parseKafkaMessage(msg *sarama.ConsumerMessage) WSMessage {
	//Somehow parse the key to get groupId or someshit
	target := string(msg.Key)
	var message = WSMessage {
		Target: target,
		Data: msg.Value,
	}
	return message
}
