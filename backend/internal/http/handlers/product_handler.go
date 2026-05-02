package handlers

import (
	"errors"
	"fmt"
	"math"
	"strings"

	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type ProductHandler struct {
	deps Deps
}

func NewProductHandler(deps Deps) *ProductHandler {
	return &ProductHandler{deps: deps}
}

type addProductRequest struct {
	Name string  `json:"name"`
	Cost float64 `json:"cost"`
}

func (h *ProductHandler) AddProduct(c *fiber.Ctx) error {
	var req addProductRequest
	if err := c.BodyParser(&req); err != nil {
		return writeError(c, fiber.StatusBadRequest, "invalid request payload")
	}

	req.Name = strings.TrimSpace(req.Name)
	if req.Name == "" {
		return writeError(c, fiber.StatusBadRequest, "name is required")
	}

	cost, err := parseProductCost(req.Cost)
	if err != nil {
		return writeError(c, fiber.StatusBadRequest, err.Error())
	}

	if err := h.deps.Queries.CreateProduct(c.UserContext(), sqlc.CreateProductParams{
		Name: req.Name,
		Cost: cost,
	}); err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to create product")
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "product created"})
}

func (h *ProductHandler) DeleteProduct(c *fiber.Ctx) error {
	productID, err := uuid.Parse(strings.TrimSpace(c.Params("productId")))
	if err != nil {
		return writeError(c, fiber.StatusBadRequest, "invalid product id")
	}

	if _, err := h.deps.Queries.DeleteProduct(c.UserContext(), productID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return writeError(c, fiber.StatusNotFound, "product not found")
		}
		return writeError(c, fiber.StatusInternalServerError, "failed to delete product")
	}

	return c.JSON(fiber.Map{"message": "product deleted"})
}

func (h *ProductHandler) ListProducts(c *fiber.Ctx) error {
	rows, err := h.deps.Queries.ListProducts(c.UserContext())
	if err != nil {
		return writeError(c, fiber.StatusInternalServerError, "failed to list products")
	}

	items := make([]fiber.Map, 0, len(rows))
	for _, row := range rows {
		cost, err := numericToFloat64(row.Cost)
		if err != nil {
			return writeError(c, fiber.StatusInternalServerError, "failed to parse product cost")
		}

		items = append(items, fiber.Map{
			"id":         row.ID,
			"name":       row.Name,
			"cost":       cost,
			"created_at": pgTimestampToISO(row.CreatedAt),
			"updated_at": pgTimestampToISO(row.UpdatedAt),
		})
	}

	return c.JSON(fiber.Map{"products": items})
}

func parseProductCost(value float64) (pgtype.Numeric, error) {
	if math.IsNaN(value) || math.IsInf(value, 0) {
		return pgtype.Numeric{}, errors.New("cost must be a valid number")
	}
	if value < 0 {
		return pgtype.Numeric{}, errors.New("cost must be non-negative")
	}

	rounded := math.Round(value*100) / 100
	var numeric pgtype.Numeric
	if err := numeric.Scan(fmt.Sprintf("%.2f", rounded)); err != nil {
		return pgtype.Numeric{}, errors.New("cost must be a valid number")
	}

	return numeric, nil
}

func numericToFloat64(value pgtype.Numeric) (float64, error) {
	floatValue, err := value.Float64Value()
	if err != nil {
		return 0, err
	}
	if !floatValue.Valid {
		return 0, nil
	}
	return floatValue.Float64, nil
}
