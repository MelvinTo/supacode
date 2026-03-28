# Supacode API — Endpoint Reference

## GET /health

Health check and version info.

**Response:**
```json
{
  "status": "ok",
  "version": "0.7.3"
}
```

---

## GET /repositories

List all registered repositories.

**Response:**
```json
[
  {
    "id": "/Users/you/repos/myproject/.bare",
    "name": "myproject",
    "rootURL": "/Users/you/repos/myproject/.bare",
    "worktreeCount": 3
  }
]
```

---

## GET /repositories/:id

Get repository detail including all worktrees.

**Response:**
```json
{
  "id": "/Users/you/repos/myproject/.bare",
  "name": "myproject",
  "rootURL": "/Users/you/repos/myproject/.bare",
  "worktrees": [
    {
      "id": "/Users/you/repos/myproject/main",
      "name": "main",
      "detail": "main",
      "workingDirectory": "/Users/you/repos/myproject/main",
      "repositoryRootURL": "/Users/you/repos/myproject/.bare",
      "repositoryID": "/Users/you/repos/myproject/.bare",
      "isSelected": true,
      "createdAt": "2025-01-15T10:30:00Z"
    }
  ]
}
```

---

## GET /repositories/:id/worktrees

List worktrees for a specific repository.

**Response:** Array of worktree objects (same shape as in repository detail).

---

## POST /repositories/:id/worktrees

Create a new worktree with an auto-generated name.

**Request body:** None required.

**Response:** `202 Accepted`
```json
{ "status": "accepted" }
```

---

## GET /worktrees/:id

Get a single worktree by ID.

**Response:**
```json
{
  "id": "/Users/you/repos/myproject/feature-xyz",
  "name": "feature-xyz",
  "detail": "feature-xyz",
  "workingDirectory": "/Users/you/repos/myproject/feature-xyz",
  "repositoryRootURL": "/Users/you/repos/myproject/.bare",
  "repositoryID": "/Users/you/repos/myproject/.bare",
  "isSelected": false,
  "createdAt": "2025-03-28T14:00:00Z"
}
```

---

## POST /worktrees/:id/select

Select (focus) a worktree in the Supacode UI.

**Response:** `202 Accepted`

---

## POST /worktrees/:id/archive

Archive a worktree.

**Response:** `202 Accepted`

---

## POST /worktrees/:id/unarchive

Unarchive a previously archived worktree.

**Response:** `202 Accepted`

---

## DELETE /worktrees/:id

Delete a worktree. This triggers a confirmation flow in the app.

**Response:** `202 Accepted`

---

## POST /worktrees/:id/terminal/tab

Create a new terminal tab in the worktree. Also selects the worktree.

**Response:** `202 Accepted`

---

## POST /worktrees/:id/terminal/close-tab

Close the currently focused terminal tab in the worktree.

**Response:** `202 Accepted`

---

## POST /worktrees/:id/terminal/run-script

Run a shell script in the worktree's terminal.

**Request body (required):**
```json
{
  "script": "npm test"
}
```

**Response:** `202 Accepted`

**Error responses:**
- `400` if body is missing or invalid JSON

---

## POST /worktrees/:id/terminal/stop-script

Stop a currently running script in the worktree.

**Response:** `202 Accepted`

---

## Error Responses

All errors return JSON:

```json
{
  "error": "Description of what went wrong"
}
```

| Status | Meaning |
|--------|---------|
| 400 | Bad request (missing/invalid body) |
| 404 | Resource not found |
| 405 | Method not allowed |
| 500 | Internal server error |
