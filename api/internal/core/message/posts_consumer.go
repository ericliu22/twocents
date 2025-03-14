package message

import (
	"log"

	"github.com/IBM/sarama"
	"github.com/gin-gonic/gin"
)

const POST_TOPIC = "posts"

func setupPostsConsumer(consumer sarama.Consumer, hub *Hub) {

	postConsumer, err := consumer.ConsumePartition(POST_TOPIC, 0, sarama.OffsetNewest)
	if err != nil {
		log.Fatal("Error creating partition consumer" + err.Error())
		return
	}
	go func() {
		// Ensure we clean up when this goroutine exits.
		defer func() {
			if err := postConsumer.Close(); err != nil {
				gin.DefaultWriter.Write([]byte("Error closing parition consumer" + err.Error()))
			}
		}()

		for {
			select {
			case err := <-postConsumer.Errors():
				gin.DefaultWriter.Write([]byte("Kafka consumer error" + err.Error()))
			case msg := <-postConsumer.Messages():
				wsMessage, err := parseKafkaMessage(msg)
				if err != nil {
					gin.DefaultWriter.Write([]byte("Failed to parse kafka message" + err.Error()))
				}
				if wsMessage != nil {
					hub.Broadcast(*wsMessage)
				}
			}
		}
	}()
}
