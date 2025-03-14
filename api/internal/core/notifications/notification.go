package notifications

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

// https://developer.apple.com/documentation/usernotifications/generating-a-remote-notification
type APSBody struct {
	APSAlert         Alert   `json:"alert" binding:"required"`
	Badge            *int    `json:"badge"`
	Sound            *string `json:"sound"`
	ThreadId         *string `json:"thread-id"`
	Category         *string `json:"category"`
	ContentAvailable *int    `json:"content-available"`
}

func SendNotification(ctx context.Context, deviceToken string, aps APSBody) {
	var apn_url string
	if os.Getenv("STAGE") == "PRODUCTION" {
		apn_url = "https://api.push.apple.com"
	} else {
		apn_url = "https://api.sandbox.push.apple.com"
	}
	jsonBytes, err := json.Marshal(aps)
	if err != nil {
		gin.DefaultWriter.Write([]byte("Failed writing json"))
		return
	}
	jsonReader := bytes.NewReader(jsonBytes)
	buf := make([]byte, len(jsonBytes))
	if _, err := io.ReadFull(jsonReader, buf); err != nil {
		gin.DefaultWriter.Write([]byte("Failed reading json"))
		return
	}

	response, err := http.Post(apn_url, "application/json", jsonReader)
	if err != nil {
		gin.DefaultWriter.Write([]byte("Failed to send notification" + err.Error()))
		return
	}
	if response.StatusCode != http.StatusOK {
		gin.DefaultWriter.Write([]byte("Invalid server response"))
		return
	}
}
