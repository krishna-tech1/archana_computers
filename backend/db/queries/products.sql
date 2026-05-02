-- name: CreateProduct :exec
INSERT INTO products (name, cost)
VALUES ($1, $2);

-- name: ListProducts :many
SELECT id, name, cost, created_at, updated_at
FROM products
ORDER BY created_at DESC;

-- name: DeleteProduct :one
DELETE FROM products
WHERE id = $1
RETURNING id;
