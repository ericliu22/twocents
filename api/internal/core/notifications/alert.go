package notifications

// https://developer.apple.com/documentation/usernotifications/generating-a-remote-notification
type Alert struct {
	Title       string  `json:"title" binding:"required"`
	Subtitle    *string `json:"subtitle"`
	Body        *string `json:"body"`
	LaunchImage *string `json:"launch-image"`
}
