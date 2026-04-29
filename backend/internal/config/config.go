package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	AppPort           string
	DatabaseURL       string
	SessionCookieName string
	SessionTTL        time.Duration
	CookieSecure      bool
}

func Load() (Config, error) {
	if os.Getenv("RAILWAY_ENVIRONMENT_NAME") == "" {
		err := godotenv.Load() // only load .env in local dev
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error loading .env file: %v\n", err)
			os.Exit(1)
		}
	}

	cfg := Config{}
	cfg.AppPort = getEnv("APP_PORT", "8080")
	cfg.DatabaseURL = strings.TrimSpace(os.Getenv("DATABASE_URL"))
	cfg.SessionCookieName = getEnv("SESSION_COOKIE_NAME", "ac_session")

	ttlHours, err := getIntEnv("SESSION_TTL_HOURS", 24)
	if err != nil {
		return Config{}, err
	}
	cfg.SessionTTL = time.Duration(ttlHours) * time.Hour

	cookieSecure, err := getBoolEnv("COOKIE_SECURE", false)
	if err != nil {
		return Config{}, err
	}
	cfg.CookieSecure = cookieSecure

	if err := cfg.validate(); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func (c Config) validate() error {
	var missing []string
	if c.DatabaseURL == "" {
		missing = append(missing, "DATABASE_URL")
	}

	if len(missing) > 0 {
		return fmt.Errorf("missing required environment variables: %s", strings.Join(missing, ", "))
	}

	if c.SessionTTL <= 0 {
		return errors.New("SESSION_TTL_HOURS must be greater than zero")
	}

	return nil
}

func getEnv(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func getIntEnv(key string, fallback int) (int, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return 0, fmt.Errorf("%s must be an integer", key)
	}
	return parsed, nil
}

func getBoolEnv(key string, fallback bool) (bool, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return false, fmt.Errorf("%s must be true or false", key)
	}
	return parsed, nil
}
