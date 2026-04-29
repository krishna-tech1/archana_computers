package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/Maestrominds/archana-computers-ticketing/internal/config"
	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/session"
	"github.com/google/uuid"
)

const (
	sessionUserIDKey = "user_id"
	sessionRoleKey   = "role"
	authLocalKey     = "auth_user"
)

type AuthUser struct {
	UserID uuid.UUID
	Role   sqlc.UserRole
}

type SessionManager struct {
	store *session.Store
	ttl   time.Duration
}

func NewSessionManager(cfg config.Config) *SessionManager {
	store := session.New(session.Config{
		Expiration:     cfg.SessionTTL,
		CookieHTTPOnly: true,
		CookieSecure:   cfg.CookieSecure,
		CookieSameSite: "lax",
		KeyLookup:      fmt.Sprintf("cookie:%s", cfg.SessionCookieName),
	})
	return &SessionManager{store: store, ttl: cfg.SessionTTL}
}

func (sm *SessionManager) Login(c *fiber.Ctx, user sqlc.User) error {
	sess, err := sm.store.Get(c)
	if err != nil {
		return err
	}

	sess.Set(sessionUserIDKey, user.ID.String())
	sess.Set(sessionRoleKey, string(user.Role))
	sess.SetExpiry(sm.ttl)

	if err := sess.Save(); err != nil {
		return err
	}

	c.Locals(authLocalKey, AuthUser{UserID: user.ID, Role: user.Role})
	return nil
}

func (sm *SessionManager) Destroy(c *fiber.Ctx) error {
	sess, err := sm.store.Get(c)
	if err != nil {
		return err
	}
	return sess.Destroy()
}

func (sm *SessionManager) CurrentUser(c *fiber.Ctx) (AuthUser, error) {
	if authUser, ok := c.Locals(authLocalKey).(AuthUser); ok {
		return authUser, nil
	}

	sess, err := sm.store.Get(c)
	if err != nil {
		return AuthUser{}, err
	}

	rawUserID := sess.Get(sessionUserIDKey)
	rawRole := sess.Get(sessionRoleKey)
	if rawUserID == nil || rawRole == nil {
		return AuthUser{}, errors.New("no active session")
	}

	userIDStr, ok := rawUserID.(string)
	if !ok {
		return AuthUser{}, errors.New("invalid session user id")
	}
	roleStr, ok := rawRole.(string)
	if !ok {
		return AuthUser{}, errors.New("invalid session role")
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return AuthUser{}, err
	}

	authUser := AuthUser{UserID: userID, Role: sqlc.UserRole(roleStr)}
	c.Locals(authLocalKey, authUser)
	return authUser, nil
}

func (sm *SessionManager) RequireAuth() fiber.Handler {
	return func(c *fiber.Ctx) error {
		_, err := sm.CurrentUser(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "authentication required"})
		}
		return c.Next()
	}
}

func (sm *SessionManager) RequireRole(roles ...sqlc.UserRole) fiber.Handler {
	allowed := map[sqlc.UserRole]bool{}
	for _, role := range roles {
		allowed[role] = true
	}

	return func(c *fiber.Ctx) error {
		authUser, err := sm.CurrentUser(c)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "authentication required"})
		}
		if !allowed[authUser.Role] {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "insufficient permissions"})
		}
		return c.Next()
	}
}

func AuthUserFromContext(c *fiber.Ctx) (AuthUser, bool) {
	authUser, ok := c.Locals(authLocalKey).(AuthUser)
	return authUser, ok
}
