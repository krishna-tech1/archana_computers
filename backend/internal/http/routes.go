package http

import (
	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/Maestrominds/archana-computers-ticketing/internal/http/handlers"
	"github.com/gofiber/fiber/v2"
)

func RegisterRoutes(app *fiber.App, deps handlers.Deps) {
	authHandler := handlers.NewAuthHandler(deps)
	clientHandler := handlers.NewClientHandler(deps)
	productHandler := handlers.NewProductHandler(deps)
	ticketHandler := handlers.NewTicketHandler(deps)

	api := app.Group("/api")
	api.Post("/login", authHandler.Login)
	api.Post("/logout", deps.Sessions.RequireAuth(), authHandler.Logout)

	api.Post(
		"/clients",
		deps.Sessions.RequireAuth(),
		deps.Sessions.RequireRole(sqlc.UserRoleAdmin),
		clientHandler.CreateClient,
	)
	api.Put(
		"/clients/:clientId",
		deps.Sessions.RequireAuth(),
		deps.Sessions.RequireRole(sqlc.UserRoleAdmin),
		clientHandler.UpdateClient,
	)
	api.Patch(
		"/clients/:clientId/reset-password",
		deps.Sessions.RequireAuth(),
		deps.Sessions.RequireRole(sqlc.UserRoleAdmin),
		clientHandler.ResetClientPassword,
	)
	api.Get(
		"/clients",
		deps.Sessions.RequireAuth(),
		deps.Sessions.RequireRole(sqlc.UserRoleAdmin),
		clientHandler.ListClients,
	)

	api.Post("/tickets", deps.Sessions.RequireAuth(), ticketHandler.CreateTicket)
	api.Get("/tickets", deps.Sessions.RequireAuth(), ticketHandler.ListTickets)
	api.Patch(
		"/tickets/:ticketId/status",
		deps.Sessions.RequireAuth(),
		deps.Sessions.RequireRole(sqlc.UserRoleAdmin),
		ticketHandler.UpdateTicketStatus,
	)

	api.Put(
		"/products",
		deps.Sessions.RequireAuth(),
		deps.Sessions.RequireRole(sqlc.UserRoleAdmin),
		productHandler.AddProduct,
	)
	api.Delete(
		"/products/:productId",
		deps.Sessions.RequireAuth(),
		deps.Sessions.RequireRole(sqlc.UserRoleAdmin),
		productHandler.DeleteProduct,
	)
	api.Get("/products", productHandler.ListProducts)
}
