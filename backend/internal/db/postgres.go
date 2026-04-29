package db

import (
	"context"
	"fmt"

	"github.com/Maestrominds/archana-computers-ticketing/internal/config"
	"github.com/Maestrominds/archana-computers-ticketing/internal/db/sqlc"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Store struct {
	Pool    *pgxpool.Pool
	Queries *sqlc.Queries
}

func NewPool(ctx context.Context, cfg config.Config) (*pgxpool.Pool, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse database url: %w", err)
	}

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("create pgx pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping postgres: %w", err)
	}

	return pool, nil
}

func NewStore(pool *pgxpool.Pool) *Store {
	return &Store{
		Pool:    pool,
		Queries: sqlc.New(pool),
	}
}
