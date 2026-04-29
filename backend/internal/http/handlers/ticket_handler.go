package handlers

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Maestrominds/archana-computers-ticketing/internal/auth"
	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/Maestrominds/archana-computers-ticketing/internal/tickets"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type TicketHandler struct {
	deps Deps
}

func NewTicketHandler(deps Deps) *TicketHandler {
	return &TicketHandler{deps: deps}
}

type createTicketRequest struct {
	ClientID string `json:"client_id"`
	Title    string `json:"title"`
	Type     string `json:"type"`
	Remarks  string `json:"remarks"`
}

type updateTicketStatusRequest struct {
	Status string `json:"status"`
}

func (h *TicketHandler) CreateTicket(c *fiber.Ctx) error {
	authUser, ok := auth.AuthUserFromContext(c)
	if !ok {
		return writeError(c, fiber.StatusUnauthorized, "authentication required")
	}

	req, err := parseCreateTicketPayload(c)
	if err != nil {
		return writeError(c, fiber.StatusBadRequest, err.Error())
	}

	req.Title = strings.TrimSpace(req.Title)
	req.Type = strings.TrimSpace(req.Type)
	req.Remarks = strings.TrimSpace(req.Remarks)
	if req.Title == "" || req.Type == "" || req.Remarks == "" {
		return writeError(c, fiber.StatusBadRequest, "title, type and remarks are required")
	}

	ctx := c.UserContext()
	clientID, err := h.resolveClientID(ctx, authUser, req.ClientID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return writeError(c, fiber.StatusNotFound, "client not found")
		}
		return writeError(c, fiber.StatusBadRequest, err.Error())
	}

	const maxTicketNoAttempts = 8
	for i := 0; i < maxTicketNoAttempts; i++ {
		createdTicket, err := h.createTicketTxn(ctx, clientID, req.Title, req.Type, req.Remarks)
		if err != nil {
			if isTicketNumberConflict(err) {
				continue
			}
			return writeError(c, fiber.StatusInternalServerError, fmt.Sprintf("failed to create ticket: %v", err))
		}

		return c.Status(fiber.StatusCreated).JSON(fiber.Map{
			"id":         createdTicket.ID,
			"client_id":  createdTicket.ClientID,
			"ticket_no":  createdTicket.TicketNo,
			"title":      createdTicket.Title,
			"type":       createdTicket.Type,
			"remarks":    createdTicket.Remarks,
			"status":     createdTicket.Status,
			"created_at": pgTimestampToISO(createdTicket.CreatedAt),
			"updated_at": pgTimestampToISO(createdTicket.UpdatedAt),
		})
	}

	return writeError(c, fiber.StatusInternalServerError, "failed to allocate unique ticket number")
}

func (h *TicketHandler) ListTickets(c *fiber.Ctx) error {
	authUser, ok := auth.AuthUserFromContext(c)
	if !ok {
		return writeError(c, fiber.StatusUnauthorized, "authentication required")
	}

	status, valid := normalizeStatus(c.Query("status"))
	if !valid {
		return writeError(c, fiber.StatusBadRequest, "status must be new, processing, or completed")
	}

	ctx := c.UserContext()
	if authUser.Role == sqlc.UserRoleAdmin {
		rows, err := h.deps.Queries.ListTicketsForAdmin(ctx, status)
		if err != nil {
			return writeError(c, fiber.StatusInternalServerError, "failed to list tickets")
		}
		items := make([]fiber.Map, 0, len(rows))
		for _, row := range rows {
			items = append(items, fiber.Map{
				"id":           row.ID,
				"client_id":    row.ClientID,
				"ticket_no":    row.TicketNo,
				"title":        row.Title,
				"type":         row.Type,
				"remarks":      row.Remarks,
				"status":       row.Status,
				"client_name":  row.ClientName,
				"client_email": row.ClientEmail,
				"created_at":   pgTimestampToISO(row.CreatedAt),
				"updated_at":   pgTimestampToISO(row.UpdatedAt),
			})
		}
		return c.JSON(fiber.Map{"tickets": items})
	}

	client, err := h.deps.Queries.GetClientByUserID(ctx, authUser.UserID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return writeError(c, fiber.StatusNotFound, "client profile not found")
		}
		return writeError(c, fiber.StatusInternalServerError, "failed to fetch client profile")
	}

	rows, err := h.deps.Queries.ListTicketsForClient(ctx, sqlc.ListTicketsForClientParams{
		ClientID: client.ID,
		Column2:  status,
	})
	if err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to list tickets")
	}

	items := make([]fiber.Map, 0, len(rows))
	for _, row := range rows {
		items = append(items, fiber.Map{
			"id":         row.ID,
			"client_id":  row.ClientID,
			"ticket_no":  row.TicketNo,
			"title":      row.Title,
			"type":       row.Type,
			"remarks":    row.Remarks,
			"status":     row.Status,
			"created_at": pgTimestampToISO(row.CreatedAt),
			"updated_at": pgTimestampToISO(row.UpdatedAt),
		})
	}

	return c.JSON(fiber.Map{"tickets": items})
}

func (h *TicketHandler) UpdateTicketStatus(c *fiber.Ctx) error {
	ticketID, err := uuid.Parse(strings.TrimSpace(c.Params("ticketId")))
	if err != nil {
		return writeError(c, fiber.StatusBadRequest, "invalid ticket id")
	}

	var req updateTicketStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return writeError(c, fiber.StatusBadRequest, "invalid request payload")
	}

	status, valid := normalizeStatus(req.Status)
	if !valid || status == "" {
		return writeError(c, fiber.StatusBadRequest, "status must be new, processing, or completed")
	}

	ctx := c.UserContext()
	ticket, err := h.deps.Queries.GetTicketByID(ctx, ticketID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return writeError(c, fiber.StatusNotFound, "ticket not found")
		}
		return writeError(c, fiber.StatusInternalServerError, "failed to load ticket")
	}

	if !isValidStatusTransition(string(ticket.Status), status) {
		return writeError(c, fiber.StatusBadRequest, "invalid status transition")
	}

	updated, err := h.deps.Queries.UpdateTicketStatus(ctx, sqlc.UpdateTicketStatusParams{
		ID:     ticketID,
		Status: sqlc.TicketStatus(status),
	})
	if err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to update ticket status")
	}

	return c.JSON(fiber.Map{
		"id":         updated.ID,
		"client_id":  updated.ClientID,
		"ticket_no":  updated.TicketNo,
		"title":      updated.Title,
		"type":       updated.Type,
		"remarks":    updated.Remarks,
		"status":     updated.Status,
		"created_at": pgTimestampToISO(updated.CreatedAt),
		"updated_at": pgTimestampToISO(updated.UpdatedAt),
	})
}

func (h *TicketHandler) resolveClientID(ctx context.Context, authUser auth.AuthUser, rawClientID string) (uuid.UUID, error) {
	if authUser.Role == sqlc.UserRoleClient {
		client, err := h.deps.Queries.GetClientByUserID(ctx, authUser.UserID)
		if err != nil {
			return uuid.Nil, err
		}
		return client.ID, nil
	}

	parsedClientID, err := uuid.Parse(strings.TrimSpace(rawClientID))
	if err != nil {
		return uuid.Nil, errors.New("client_id is required for admin ticket creation")
	}

	if _, err := h.deps.Queries.GetClientByID(ctx, parsedClientID); err != nil {
		return uuid.Nil, err
	}

	return parsedClientID, nil
}

func (h *TicketHandler) createTicketTxn(ctx context.Context, clientID uuid.UUID, title string, ttype string, remarks string) (sqlc.Ticket, error) {
	tx, err := h.deps.Pool.Begin(ctx)
	if err != nil {
		return sqlc.Ticket{}, err
	}
	defer tx.Rollback(ctx)

	qtx := h.deps.Queries.WithTx(tx)
	ticketNo, err := tickets.GenerateTicketNumber(time.Now())
	if err != nil {
		return sqlc.Ticket{}, err
	}

	createdTicket, err := qtx.CreateTicket(ctx, sqlc.CreateTicketParams{
		ClientID: clientID,
		TicketNo: ticketNo,
		Title:    title,
		Type:     ttype,
		Remarks:  remarks,
	})
	if err != nil {
		return sqlc.Ticket{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return sqlc.Ticket{}, err
	}

	return createdTicket, nil
}

func parseCreateTicketPayload(c *fiber.Ctx) (createTicketRequest, error) {
	ct := c.Get(fiber.HeaderContentType)
	if strings.HasPrefix(ct, fiber.MIMEApplicationJSON) {
		var req createTicketRequest
		if err := c.BodyParser(&req); err != nil {
			return createTicketRequest{}, errors.New("invalid request payload")
		}
		return req, nil
	}

	form, err := c.MultipartForm()
	if err != nil {
		return createTicketRequest{}, errors.New("multipart form is invalid")
	}

	req := createTicketRequest{
		ClientID: firstFormValue(form.Value, "client_id"),
		Title:    firstFormValue(form.Value, "title"),
		Type:     firstFormValue(form.Value, "type"),
		Remarks:  firstFormValue(form.Value, "remarks"),
	}

	return req, nil
}

func firstFormValue(values map[string][]string, key string) string {
	list := values[key]
	if len(list) == 0 {
		return ""
	}
	return list[0]
}

func isTicketNumberConflict(err error) bool {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return false
	}
	return pgErr.Code == "23505" && strings.Contains(pgErr.ConstraintName, "ticket_no")
}

func isValidStatusTransition(current string, next string) bool {
	if current == next {
		return true
	}
	switch current {
	case string(sqlc.TicketStatusNew):
		return next == string(sqlc.TicketStatusProcessing)
	case string(sqlc.TicketStatusProcessing):
		return next == string(sqlc.TicketStatusCompleted)
	case string(sqlc.TicketStatusCompleted):
		return false
	default:
		return false
	}
}
