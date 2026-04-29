package tickets

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"time"
)

func GenerateTicketNumber(now time.Time) (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(10000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("TKT-%s-%04d", now.UTC().Format("20060102"), n.Int64()), nil
}
