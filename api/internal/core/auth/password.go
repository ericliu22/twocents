package auth

import (
	"crypto/rand"
	"encoding/base64"

	"golang.org/x/crypto/argon2"
)

type HashedPassword struct {
	Hash string
	Salt []byte
}

func hashPassword(password []byte, salt []byte) string {
	hash := argon2.IDKey(password, salt, 1, 64*1024, 4, 32)
	return base64.RawStdEncoding.EncodeToString(hash)
}

func generateSalt() ([]byte, error) {
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
	  return nil, err
	}
	return salt, nil
}

func GenerateHashedPassword(plaintext []byte) (*HashedPassword, error) {
	salt, err := generateSalt()
	if err != nil {
		return nil, err
	}
	hash := hashPassword(plaintext, salt)
	var hashedPassword HashedPassword
	hashedPassword = HashedPassword {
		Hash: hash,
		Salt: salt,
	}
	return &hashedPassword, nil
}
