DROP INDEX IF EXISTS idx_tickets_status;
DROP INDEX IF EXISTS idx_tickets_client_id;
DROP INDEX IF EXISTS idx_users_email;

DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS users;

DROP TYPE IF EXISTS ticket_status;
DROP TYPE IF EXISTS user_role;
