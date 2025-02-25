package auth

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func generateJWT(userID string, secret []byte) (string, error) {
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "sub": userID,
        "exp": time.Now().Add(time.Hour * 1).Unix(),
    })
    return token.SignedString(secret)
}
