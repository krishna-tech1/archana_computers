package security

import (
	"crypto/rand"
	"errors"
	"math/big"

	"golang.org/x/crypto/bcrypt"
)

const passwordAlphabet = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789@#$%&*"

func GeneratePassword(length int) (string, error) {
	if length < 8 {
		return "", errors.New("password length must be at least 8")
	}

	buffer := make([]byte, length)
	max := big.NewInt(int64(len(passwordAlphabet)))
	for i := 0; i < length; i++ {
		n, err := rand.Int(rand.Reader, max)
		if err != nil {
			return "", err
		}
		buffer[i] = passwordAlphabet[n.Int64()]
	}

	return string(buffer), nil
}

func HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

func VerifyPassword(password string, passwordHash string) error {
	return bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password))
}
