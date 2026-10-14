# GameSphere API starter

Base URL locally: `http://localhost:3000/api`

## Health

`GET /health` returns a simple service health object. This endpoint is used by Render's health check.

## Planned API groups

- `GET /games`, `GET /games/:slug`
- `GET /profiles/:username`, `PATCH /profiles/me`
- `GET /posts`, `POST /posts`, `POST /posts/:id/comments`, `POST /posts/:id/likes`
- `GET /tournaments`, `POST /tournaments`, `POST /tournaments/:id/register`
- `GET /tournaments/:id/bracket`, `POST /matches/:id/report`, `POST /matches/:id/approve`
- `GET /leaderboards/:gameSlug`

These are planned endpoints, not implemented yet. Validate all input, authenticate requests, enforce authorization and rate limits, and never trust client-supplied XP, roles, or match winners.
