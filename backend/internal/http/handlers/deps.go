package handlers

import (
	"errors"
	"strings"
	"time"

	"github.com/Maestrominds/archana-computers-ticketing/internal/auth"
	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Deps struct {
	Pool     *pgxpool.Pool
	Queries  *sqlc.Queries
	Sessions *auth.SessionManager
}

func writeError(c *fiber.Ctx, status int, message string) error {
	return c.Status(status).JSON(fiber.Map{"error": message})
}

func pgTimestampToISO(ts pgtype.Timestamptz) string {
	if !ts.Valid {
		return ""
	}
	return ts.Time.UTC().Format(time.RFC3339)
}

func normalizeStatus(raw string) (string, bool) {
	raw = strings.TrimSpace(strings.ToLower(raw))
	switch raw {
	case "", string(sqlc.TicketStatusNew), string(sqlc.TicketStatusProcessing), string(sqlc.TicketStatusCompleted):
		return raw, true
	default:
		return "", false
	}
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return false
	}
	return pgErr.Code == "23505"
}
