/**
 * Writa API - Cloudflare Workers Entry Point
 *
 * Main API server handling:
 * - Authentication (Clerk JWT verification)
 * - Document CRUD and sync
 * - Workspace management
 * - User settings
 * - File uploads (R2)
 */

import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";

import { authMiddleware } from "./middleware/auth";
import { documentRoutes } from "./routes/documents";
import { workspaceRoutes } from "./routes/workspaces";
import { settingsRoutes } from "./routes/settings";
import { syncRoutes } from "./routes/sync";
import { uploadRoutes } from "./routes/upload";

// Environment bindings type
export interface Env {
  DB: D1Database;
  R2_BUCKET: R2Bucket;
  CLERK_SECRET_KEY: string;
  CLERK_PUBLISHABLE_KEY: string;
  ENVIRONMENT: string;
  CORS_ORIGIN: string;
}

// Request context variables
export interface Variables {
  userId: string;
}

// Create Hono app
const app = new Hono<{ Bindings: Env; Variables: Variables }>();

// Global middleware
app.use("*", logger());
app.use(
  "*",
  cors({
    origin: (origin, c) => {
      // Allow configured origin or all in dev
      const corsOrigin = c.env.CORS_ORIGIN;
      if (corsOrigin === "*") return origin;
      return corsOrigin;
    },
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
    exposeHeaders: ["X-Request-Id"],
    credentials: true,
  })
);

// Health check (no auth required)
app.get("/", (c) => {
  return c.json({
    name: "Writa API",
    version: "1.0.0",
    status: "healthy",
    environment: c.env.ENVIRONMENT,
  });
});

app.get("/health", (c) => {
  return c.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Protected API routes
const api = new Hono<{ Bindings: Env; Variables: Variables }>();

// Apply auth middleware to all API routes
api.use("*", authMiddleware);

// Mount route handlers
api.route("/documents", documentRoutes);
api.route("/workspaces", workspaceRoutes);
api.route("/settings", settingsRoutes);
api.route("/sync", syncRoutes);
api.route("/upload", uploadRoutes);

// Mount API under /api prefix
app.route("/api", api);

// 404 handler
app.notFound((c) => {
  return c.json({ error: "Not found", path: c.req.path }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error("API Error:", err);
  return c.json(
    {
      error: "Internal server error",
      message: c.env.ENVIRONMENT === "development" ? err.message : undefined,
    },
    500
  );
});

export default app;
