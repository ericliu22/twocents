package message

import (
	"log"
	"strings"

	"github.com/IBM/sarama"
	"github.com/google/uuid"
)

func SetupKafkaConsumer(hub *Hub) {
	// Set up Sarama consumer configuration.
	config := sarama.NewConfig()
	config.Consumer.Return.Errors = true

	// List of Kafka broker addresses.
	brokers := []string{"broker:9092"}
	// The topic to consume post events from.

	// Create a new consumer.
	var consumer sarama.Consumer
	var err error

	for i := 0; i < 10; i++ {
		consumer, err = sarama.NewConsumer(brokers, config)
		if err == nil {
			break
		}
		log.Printf("Attempt %d: Error creating Kafka consumer: %v\n", i+1, err)
		time.Sleep(5 * time.Second)  // Wait before retrying
	}

	if err != nil {
		log.Printf("Error creating kafka consumer" + err.Error())
		return
	}

	setupPostsConsumer(consumer, hub)
	// For demonstration, we consume from partition 0 starting at the newest offset.
}

func parseKafkaMessage(msg *sarama.ConsumerMessage) (*WSMessage, error) {
	//Somehow parse the key to get groupId or someshit

	messageKey := string(msg.Key)
	parts := strings.Split(messageKey, ":")
	subject, subjectId := parts[0], parts[1]

	target, parseErr := uuid.Parse(subjectId)
	if parseErr != nil {
		return nil, parseErr
	}

	var message WSMessage
	if subject == "group" {
		message = WSMessage{
			Group: &target,
			Data:  msg.Value,
		}
	} else {
		message = WSMessage{
			Target: &target,
			Data:   msg.Value,
		}
	}

	return &message, nil
}
