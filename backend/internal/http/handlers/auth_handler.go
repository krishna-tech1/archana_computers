package handlers

import (
	"errors"
	"strings"

	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/Maestrominds/archana-computers-ticketing/internal/security"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
)

type AuthHandler struct {
	deps Deps
}

func NewAuthHandler(deps Deps) *AuthHandler {
	return &AuthHandler{deps: deps}
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req loginRequest
	if err := c.BodyParser(&req); err != nil {
		return writeError(c, fiber.StatusBadRequest, "invalid request payload")
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || req.Password == "" {
		return writeError(c, fiber.StatusBadRequest, "email and password are required")
	}

	ctx := c.UserContext()
	user, err := h.deps.Queries.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return writeError(c, fiber.StatusUnauthorized, "invalid credentials")
		}
		return writeError(c, fiber.StatusInternalServerError, "failed to fetch user")
	}

	if err := security.VerifyPassword(req.Password, user.PasswordHash); err != nil {
		return writeError(c, fiber.StatusUnauthorized, "invalid credentials")
	}

	if err := h.deps.Sessions.Login(c, user); err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to create session")
	}

	response := fiber.Map{
		"user": fiber.Map{
			"id":    user.ID,
			"email": user.Email,
			"role":  user.Role,
		},
	}

	if user.Role == sqlc.UserRoleClient {
		client, err := h.deps.Queries.GetClientByUserID(ctx, user.ID)
		if err == nil {
			response["user"].(fiber.Map)["client_id"] = client.ID
		}
	}

	return c.JSON(response)
}

func (h *AuthHandler) Logout(c *fiber.Ctx) error {
	if err := h.deps.Sessions.Destroy(c); err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to destroy session")
	}
	return c.JSON(fiber.Map{"message": "logged out"})
}
