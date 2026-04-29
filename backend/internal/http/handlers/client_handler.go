package handlers

import (
	"errors"
	"net/mail"
	"strings"

	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/Maestrominds/archana-computers-ticketing/internal/security"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
)

type ClientHandler struct {
	deps Deps
}

func NewClientHandler(deps Deps) *ClientHandler {
	return &ClientHandler{deps: deps}
}

type createClientRequest struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Phone   string `json:"phone"`
	Address string `json:"address"`
}

func (h *ClientHandler) CreateClient(c *fiber.Ctx) error {
	var req createClientRequest
	if err := c.BodyParser(&req); err != nil {
		return writeError(c, fiber.StatusBadRequest, "invalid request payload")
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	req.Phone = strings.TrimSpace(req.Phone)
	req.Address = strings.TrimSpace(req.Address)

	if req.Name == "" || req.Email == "" || req.Phone == "" || req.Address == "" {
		return writeError(c, fiber.StatusBadRequest, "name, email, phone, and address are required")
	}

	if _, err := mail.ParseAddress(req.Email); err != nil {
		return writeError(c, fiber.StatusBadRequest, "invalid email")
	}

	generatedPassword, err := security.GeneratePassword(12)
	if err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to generate password")
	}

	passwordHash, err := security.HashPassword(generatedPassword)
	if err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to hash password")
	}

	ctx := c.UserContext()
	tx, err := h.deps.Pool.Begin(ctx)
	if err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to start transaction")
	}
	defer tx.Rollback(ctx)

	qtx := h.deps.Queries.WithTx(tx)
	createdUser, err := qtx.CreateUser(ctx, sqlc.CreateUserParams{
		Email:        req.Email,
		PasswordHash: passwordHash,
		Role:         sqlc.UserRoleClient,
	})
	if err != nil {
		if isUniqueViolation(err) {
			return writeError(c, fiber.StatusConflict, "email already exists")
		}
		return writeError(c, fiber.StatusInternalServerError, "failed to create user")
	}

	err = qtx.CreateClient(ctx, sqlc.CreateClientParams{
		UserID:  createdUser.ID,
		Name:    req.Name,
		Phone:   req.Phone,
		Address: req.Address,
	})
	if err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to create client")
	}

	if err := tx.Commit(ctx); err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to commit transaction")
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"password": generatedPassword,
	})
}

func (h *ClientHandler) ListClients(c *fiber.Ctx) error {
	rows, err := h.deps.Queries.ListClients(c.UserContext())
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return c.JSON([]fiber.Map{})
		}
		return writeError(c, fiber.StatusInternalServerError, "failed to list clients")
	}

	items := make([]fiber.Map, 0, len(rows))
	for _, row := range rows {
		items = append(items, fiber.Map{
			"id":         row.ID,
			"user_id":    row.UserID,
			"name":       row.Name,
			"email":      row.Email,
			"phone":      row.Phone,
			"address":    row.Address,
			"created_at": pgTimestampToISO(row.CreatedAt),
			"updated_at": pgTimestampToISO(row.UpdatedAt),
		})
	}

	return c.JSON(fiber.Map{"clients": items})
}
