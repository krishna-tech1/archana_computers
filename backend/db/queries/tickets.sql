-- name: CreateTicket :one
INSERT INTO tickets (client_id, ticket_no, title, type, remarks, status)
VALUES ($1, $2, $3, $4, $5, 'new')
RETURNING id, client_id, ticket_no, title, type, remarks, status, created_at, updated_at;

-- name: ListTicketsForAdmin :many
SELECT
    t.id,
    t.client_id,
    t.ticket_no,
    t.title,
    t.type,
    t.remarks,
    t.status,
    t.created_at,
    t.updated_at,
    c.name AS client_name,
    u.email AS client_email
FROM tickets t
JOIN clients c ON c.id = t.client_id
JOIN users u ON u.id = c.user_id
WHERE ($1::text = '' OR t.status::text = $1::text)
ORDER BY t.created_at DESC;

-- name: ListTicketsForClient :many
SELECT
    t.id,
    t.client_id,
    t.ticket_no,
    t.title,
    t.type,
    t.remarks,
    t.status,
    t.created_at,
    t.updated_at
FROM tickets t
WHERE t.client_id = $1
    AND ($2::text = '' OR t.status::text = $2::text)
ORDER BY t.created_at DESC;

-- name: GetTicketByID :one
SELECT
    t.id,
    t.client_id,
    t.ticket_no,
    t.title,
    t.type,
    t.remarks,
    t.status,
    t.created_at,
    t.updated_at,
    c.user_id AS client_user_id
FROM tickets t
JOIN clients c ON c.id = t.client_id
WHERE t.id = $1;

-- name: UpdateTicketStatus :one
UPDATE tickets
SET status = $2,
    updated_at = NOW()
WHERE id = $1
RETURNING id, client_id, ticket_no, title, type, remarks, status, created_at, updated_at;
