package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Maestrominds/archana-computers-ticketing/internal/auth"
	"github.com/Maestrominds/archana-computers-ticketing/internal/config"
	"github.com/Maestrominds/archana-computers-ticketing/internal/db"
	api "github.com/Maestrominds/archana-computers-ticketing/internal/http"
	"github.com/Maestrominds/archana-computers-ticketing/internal/http/handlers"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	recovermw "github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	ctx := context.Background()
	pool, err := db.NewPool(ctx, cfg)
	if err != nil {
		log.Fatalf("failed to connect postgres: %v", err)
	}
	defer pool.Close()

	store := db.NewStore(pool)
	sessions := auth.NewSessionManager(cfg)

	app := fiber.New(fiber.Config{
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	})

	app.Use(recovermw.New())
	app.Use(logger.New())

	app.Get("/healthz", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	api.RegisterRoutes(app, handlers.Deps{
		Pool:     store.Pool,
		Queries:  store.Queries,
		Sessions: sessions,
	})

	go func() {
		if err := app.Listen(":" + cfg.AppPort); err != nil {
			log.Fatalf("fiber server failed: %v", err)
		}
	}()

	shutdownSignal := make(chan os.Signal, 1)
	signal.Notify(shutdownSignal, syscall.SIGINT, syscall.SIGTERM)
	<-shutdownSignal

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := app.ShutdownWithContext(shutdownCtx); err != nil {
		log.Printf("graceful shutdown error: %v", err)
	}
}
