-- name: CreateClient :exec
INSERT INTO clients (user_id, name, phone, address)
VALUES ($1, $2, $3, $4);

-- name: GetClientByUserID :one
SELECT id, user_id, name, phone, address, created_at, updated_at
FROM clients
WHERE user_id = $1;

-- name: GetClientByID :one
SELECT id, user_id, name, phone, address, created_at, updated_at
FROM clients
WHERE id = $1;

-- name: ListClients :many
SELECT
    c.id,
    c.user_id,
    c.name,
    c.phone,
    c.address,
    c.created_at,
    c.updated_at,
    u.email
FROM clients c
JOIN users u ON u.id = c.user_id
ORDER BY c.created_at DESC;

-- name: UpdateClient :one
UPDATE clients
SET name = $2,
    phone = $3,
    address = $4,
    updated_at = NOW()
WHERE id = $1
RETURNING id, user_id, name, phone, address, created_at, updated_at;
