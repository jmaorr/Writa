# Writa API

Cloudflare Workers API backend for Writa document sync.

## Prerequisites

- Node.js 18+
- Cloudflare account
- Clerk account (for authentication)

## Setup

### 1. Install dependencies

```bash
cd api
npm install
```

### 2. Login to Cloudflare

```bash
npx wrangler login
```

### 3. Create D1 Database

```bash
npx wrangler d1 create writa-db
```

Copy the `database_id` from the output and update `wrangler.toml`.

### 4. Create R2 Bucket

```bash
npx wrangler r2 bucket create writa-files
```

### 5. Add Clerk Secrets

Get your keys from [Clerk Dashboard](https://dashboard.clerk.com) → API Keys.

```bash
npx wrangler secret put CLERK_SECRET_KEY
# Paste your Clerk secret key

npx wrangler secret put CLERK_PUBLISHABLE_KEY
# Paste your Clerk publishable key
```

### 6. Run Database Migrations

**Local development:**
```bash
npm run db:migrate
```

**Production:**
```bash
npm run db:migrate:prod
```

## Development

Start the local development server:

```bash
npm run dev
```

The API will be available at `http://localhost:8787`.

## Deployment

Deploy to Cloudflare Workers:

```bash
npm run deploy
```

## API Endpoints

### Health Check
- `GET /` - API info
- `GET /health` - Health status

### Documents (requires auth)
- `GET /api/documents` - List documents
- `GET /api/documents/:id` - Get document
- `POST /api/documents` - Create document
- `PUT /api/documents/:id` - Update document
- `DELETE /api/documents/:id` - Delete document

### Workspaces (requires auth)
- `GET /api/workspaces` - List workspaces
- `GET /api/workspaces/:id` - Get workspace
- `POST /api/workspaces` - Create workspace
- `PUT /api/workspaces/:id` - Update workspace
- `DELETE /api/workspaces/:id` - Delete workspace

### Settings (requires auth)
- `GET /api/settings` - Get user settings
- `PUT /api/settings` - Update settings
- `PATCH /api/settings` - Partial update (merge)

### Sync (requires auth)
- `GET /api/sync?since=<timestamp>` - Pull changes
- `POST /api/sync` - Push changes

### Upload (requires auth)
- `POST /api/upload` - Upload file
- `GET /api/upload/:userId/:fileId` - Get file
- `DELETE /api/upload/:userId/:fileId` - Delete file

## Authentication

All `/api/*` routes require a valid Clerk JWT token in the Authorization header:

```
Authorization: Bearer <clerk-jwt-token>
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLERK_SECRET_KEY` | Clerk backend secret key |
| `CLERK_PUBLISHABLE_KEY` | Clerk frontend publishable key |
| `ENVIRONMENT` | `development` or `production` |
| `CORS_ORIGIN` | Allowed CORS origin |

## Database Schema

See `src/db/migrations/0001_initial_schema.sql` for the complete schema.

## License

Private - Writa
