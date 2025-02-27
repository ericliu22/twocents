package middleware

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"firebase.google.com/go/v4/auth"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware creates a Gin middleware for Firebase authentication.
func AuthMiddleware(client *auth.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Retrieve the Authorization header.
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is missing"})
			return
		}

		// The expected header format is "Bearer <token>".
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			return
		}

		idToken := parts[1]

		// Verify the token using Firebase Admin SDK.
		token, err := client.VerifyIDToken(context.Background(), idToken)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			return
		}

		// Store the token in the context so that downstream handlers can access user data.
		c.Set("user", token)
		c.Next()
	}
}

func GetAuthToken(ctx *gin.Context) (*auth.Token, error) {
	value, keyExists := ctx.Get("user")
	if !keyExists {
		return nil, errors.New("Unauthorized")
	}
	token, ok := value.(*auth.Token)
	if !ok {
		return nil, errors.New("Failed to parse token")
	}

	return token, nil
}
