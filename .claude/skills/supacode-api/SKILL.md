---
name: supacode-api
description: Supacode localhost REST API for managing repositories, worktrees, and terminals programmatically. Use when you need to interact with Supacode app state, create/manage worktrees, control terminal sessions, or run scripts in worktrees.
user-invocable: true
---

# Supacode REST API

Supacode exposes a localhost REST API for programmatic control of repositories, worktrees, and terminals. The server must be enabled in Settings > Advanced > API Server.

## Base URL

```
http://127.0.0.1:19191/api/v1
```

The port (default `19191`) is configurable in settings. The server only binds to `127.0.0.1` (localhost).

## Quick Start

```bash
# Check if the API server is running
curl http://127.0.0.1:19191/api/v1/health

# List all repositories
curl http://127.0.0.1:19191/api/v1/repositories

# List worktrees for a repository
curl http://127.0.0.1:19191/api/v1/repositories/{id}/worktrees

# Select a worktree
curl -X POST http://127.0.0.1:19191/api/v1/worktrees/{id}/select

# Run a script in a worktree
curl -X POST http://127.0.0.1:19191/api/v1/worktrees/{id}/terminal/run-script \
  -H "Content-Type: application/json" \
  -d '{"script": "echo hello"}'
```

## Response Conventions

- **GET** requests return `200 OK` with JSON body
- **POST/DELETE** mutations return `202 Accepted` (fire-and-forget); poll GET endpoints for updated state
- Errors return `{"error": "message"}` with appropriate HTTP status codes (400, 404, 405, 500)

## Endpoints

See [endpoints.md](endpoints.md) for full reference.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check + app version |
| GET | `/repositories` | List all repositories |
| GET | `/repositories/:id` | Repository detail with worktrees |
| GET | `/repositories/:id/worktrees` | Worktrees for a repository |
| GET | `/worktrees/:id` | Worktree detail |
| POST | `/repositories/:id/worktrees` | Create a new worktree |
| POST | `/worktrees/:id/select` | Select/focus a worktree |
| POST | `/worktrees/:id/archive` | Archive a worktree |
| POST | `/worktrees/:id/unarchive` | Unarchive a worktree |
| DELETE | `/worktrees/:id` | Delete a worktree |
| POST | `/worktrees/:id/terminal/tab` | Create a new terminal tab |
| POST | `/worktrees/:id/terminal/close-tab` | Close the focused terminal tab |
| POST | `/worktrees/:id/terminal/run-script` | Run a script (body: `{"script":"..."}`) |
| POST | `/worktrees/:id/terminal/stop-script` | Stop a running script |

## Common Workflows

### Create a worktree and run a command in it
```bash
# 1. Find the repository ID
REPO_ID=$(curl -s http://127.0.0.1:19191/api/v1/repositories | jq -r '.[0].id')

# 2. Create a worktree
curl -X POST http://127.0.0.1:19191/api/v1/repositories/$REPO_ID/worktrees

# 3. Wait briefly, then get the latest worktree
sleep 2
WORKTREE_ID=$(curl -s http://127.0.0.1:19191/api/v1/repositories/$REPO_ID/worktrees | jq -r '.[-1].id')

# 4. Run a script
curl -X POST http://127.0.0.1:19191/api/v1/worktrees/$WORKTREE_ID/terminal/run-script \
  -H "Content-Type: application/json" \
  -d '{"script": "npm test"}'
```

### Monitor worktree status
```bash
# Check which worktree is selected
curl -s http://127.0.0.1:19191/api/v1/repositories | \
  jq -r '.[].id' | while read repo; do
    curl -s "http://127.0.0.1:19191/api/v1/repositories/$repo/worktrees" | \
      jq '.[] | select(.isSelected == true)'
  done
```

## ACP Agent Discovery

Supacode supports the [Agent Communication Protocol](https://github.com/i-am-bee/beeai) for AI agent interoperability.

```bash
# Discover Supacode's agent card (capabilities, skills, endpoints)
curl http://127.0.0.1:19191/.well-known/agent.json
```

The agent card describes all available skills with input schemas and examples, enabling other AI agents to discover and interact with Supacode programmatically without prior knowledge of the API.

## Notes

- The API server must be enabled in Supacode settings (Settings > Advanced > API Server)
- All IDs are path-based strings (e.g., `/Users/you/repos/project/.bare`)
- IDs may contain URL-special characters — ensure proper encoding when using in paths
- Mutations are asynchronous; the app processes them after the 202 response
