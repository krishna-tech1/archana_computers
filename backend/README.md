# API Reference

All request bodies are `application/json`. All responses are `application/json` unless noted otherwise.

Authentication is **session-cookie based**. On successful login, the server sets a `Set-Cookie` header. Flutter's `http` package does **not** persist cookies automatically — use the [`cookie_jar`](https://pub.dev/packages/cookie_jar) + [`dio_cookie_manager`](https://pub.dev/packages/dio_cookie_manager) packages with `Dio`, or manually extract and forward the cookie on every subsequent request.

---

## Authentication

### POST `/api/login`

Authenticates a user and establishes a session.

**Request Headers**

| Header       | Value            |
| ------------ | ---------------- |
| Content-Type | application/json |

**Request Body**

```json
{
    "email": "string",
    "password": "string"
}
```

| Field    | Type   | Required | Description   |
| -------- | ------ | -------- | ------------- |
| email    | string | Yes      | User email    |
| password | string | Yes      | User password |

**Response** `200 OK`

```json
{
    "user": {
        "id": "string",
        "email": "string",
        "role": "string"
    }
}
```

| Field      | Type   | Description                    |
| ---------- | ------ | ------------------------------ |
| user.id    | string | Unique user identifier         |
| user.email | string | Authenticated user's email     |
| user.role  | string | Either `"admin"` or `"client"` |

> **Flutter note:** Capture the `Set-Cookie` response header and include it as `Cookie: <value>` in all subsequent requests.

**Error Responses**

| Status | Meaning                   |
| ------ | ------------------------- |
| 400    | Missing or malformed body |
| 401    | Invalid credentials       |

---

### POST `/api/logout`

Terminates the current session. No request body required.

**Request Headers**

| Header | Value          |
| ------ | -------------- |
| Cookie | Session cookie |

**Response** `200 OK` — Empty body.

---

## Clients

> All `/api/clients` endpoints require **admin** role.

### POST `/api/clients`

Creates a new client account. The server generates and returns a one-time password.

**Request Headers**

| Header       | Value                |
| ------------ | -------------------- |
| Content-Type | application/json     |
| Cookie       | Admin session cookie |

**Request Body**

```json
{
    "name": "string",
    "email": "string",
    "phone": "string",
    "address": "string"
}
```

| Field   | Type   | Required | Description                 |
| ------- | ------ | -------- | --------------------------- |
| name    | string | Yes      | Full name of the client     |
| email   | string | Yes      | Login email for the client  |
| phone   | string | No       | Phone number (E.164 format) |
| address | string | No       | Client address              |

**Response** `201 Created`

```json
{
    "password": "string"
}
```

| Field    | Type   | Description                      |
| -------- | ------ | -------------------------------- |
| password | string | Auto-generated one-time password |

> **Flutter note:** Display this password immediately to the admin. It is not recoverable after this response.

**Error Responses**

| Status | Meaning                         |
| ------ | ------------------------------- |
| 400    | Missing required fields         |
| 401    | Not authenticated               |
| 403    | Authenticated user is not admin |
| 409    | Email already in use            |

---

### GET `/api/clients`

Returns a list of all registered clients.

**Request Headers**

| Header | Value                |
| ------ | -------------------- |
| Cookie | Admin session cookie |

**Response** `200 OK`

```json
{
    "clients": [
        {
            "id": "string",
            "name": "string",
            "email": "string"
        }
    ]
}
```

| Field           | Type   | Description              |
| --------------- | ------ | ------------------------ |
| clients         | array  | List of client objects   |
| clients[].id    | string | Unique client identifier |
| clients[].name  | string | Client display name      |
| clients[].email | string | Client email             |

**Error Responses**

| Status | Meaning                         |
| ------ | ------------------------------- |
| 401    | Not authenticated               |
| 403    | Authenticated user is not admin |

---

## Tickets

### POST `/api/tickets`

Creates a new support ticket. Accessible by both `admin` and `client` roles.

**Request Headers**

| Header       | Value            |
| ------------ | ---------------- |
| Content-Type | application/json |
| Cookie       | Session cookie   |

**Request Body**

```json
{
    "client_id": "string",
    "title": "string",
    "type": "string",
    "remarks": "string"
}
```

| Field     | Type   | Required   | Description                                               |
| --------- | ------ | ---------- | --------------------------------------------------------- |
| client_id | string | Admin only | Target client's ID. Ignored if the requester is a client. |
| title     | string | Yes        | Short description of the issue                            |
| type      | string | Yes        | Ticket category/type                                      |
| remarks   | string | No         | Additional context or notes                               |

**Response** `201 Created`

```json
{
    "ticket": {
        "id": "string",
        "title": "string",
        "type": "string",
        "remarks": "string",
        "status": "string",
        "client_id": "string"
    }
}
```

| Field            | Type   | Description                             |
| ---------------- | ------ | --------------------------------------- |
| ticket.id        | string | Unique ticket identifier                |
| ticket.title     | string | Ticket title                            |
| ticket.type      | string | Ticket category/type                    |
| ticket.remarks   | string | Additional notes                        |
| ticket.status    | string | Initial status — always `"new"`         |
| ticket.client_id | string | ID of the client this ticket belongs to |

**Error Responses**

| Status | Meaning                                   |
| ------ | ----------------------------------------- |
| 400    | Missing required fields                   |
| 401    | Not authenticated                         |
| 403    | Admin did not provide a valid `client_id` |

---

### GET `/api/tickets`

Returns tickets. Admins see all tickets; clients see only their own.

**Request Headers**

| Header | Value          |
| ------ | -------------- |
| Cookie | Session cookie |

**Query Parameters**

| Parameter | Type   | Required | Allowed Values                   |
| --------- | ------ | -------- | -------------------------------- |
| status    | string | No       | `new`, `processing`, `completed` |

**Response** `200 OK`

```json
{
    "tickets": [
        {
            "id": "string",
            "title": "string",
            "type": "string",
            "remarks": "string",
            "status": "string",
            "client_id": "string"
        }
    ]
}
```

| Field               | Type   | Description                             |
| ------------------- | ------ | --------------------------------------- |
| tickets             | array  | List of ticket objects                  |
| tickets[].id        | string | Unique ticket identifier                |
| tickets[].title     | string | Ticket title                            |
| tickets[].type      | string | Ticket category/type                    |
| tickets[].remarks   | string | Additional notes                        |
| tickets[].status    | string | `new`, `processing`, or `completed`     |
| tickets[].client_id | string | ID of the client this ticket belongs to |

**Error Responses**

| Status | Meaning              |
| ------ | -------------------- |
| 400    | Invalid status value |
| 401    | Not authenticated    |

---

### PATCH `/api/tickets/:ticketId/status`

Updates the status of a ticket. Requires **admin** role.

**Path Parameters**

| Parameter | Type   | Description                |
| --------- | ------ | -------------------------- |
| ticketId  | string | ID of the ticket to update |

**Request Headers**

| Header       | Value                |
| ------------ | -------------------- |
| Content-Type | application/json     |
| Cookie       | Admin session cookie |

**Request Body**

```json
{
    "status": "string"
}
```

| Field  | Type   | Required | Allowed Values                   |
| ------ | ------ | -------- | -------------------------------- |
| status | string | Yes      | `new`, `processing`, `completed` |

**Response** `200 OK`

```json
{
    "ticket": {
        "id": "string",
        "status": "string"
    }
}
```

| Field         | Type   | Description       |
| ------------- | ------ | ----------------- |
| ticket.id     | string | Ticket identifier |
| ticket.status | string | Updated status    |

**Error Responses**

| Status | Meaning                         |
| ------ | ------------------------------- |
| 400    | Invalid or missing status value |
| 401    | Not authenticated               |
| 403    | Authenticated user is not admin |
| 404    | Ticket not found                |
