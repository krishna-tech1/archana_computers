-- name: GetUserByEmail :one
SELECT id, email, password_hash, role, created_at, updated_at
FROM users
WHERE email = $1;

-- name: GetUserByID :one
SELECT id, email, password_hash, role, created_at, updated_at
FROM users
WHERE id = $1;

-- name: CreateUser :one
INSERT INTO users (email, password_hash, role)
VALUES ($1, $2, $3)
RETURNING id, email, password_hash, role, created_at, updated_at;

-- name: UpdateUserEmail :one
UPDATE users
SET email = $2,
	updated_at = NOW()
WHERE id = $1
RETURNING id, email, password_hash, role, created_at, updated_at;

-- name: UpdateUserPassword :one
UPDATE users
SET password_hash = $2,
	updated_at = NOW()
WHERE id = $1
RETURNING id, email, password_hash, role, created_at, updated_at;