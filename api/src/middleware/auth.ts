/**
 * Authentication Middleware
 *
 * Verifies Clerk JWT tokens and extracts user ID.
 * All protected routes require a valid Bearer token.
 */

import { Context, MiddlewareHandler } from "hono";
import { verifyToken } from "@clerk/backend";
import type { Env, Variables } from "../index";

export const authMiddleware: MiddlewareHandler<{
  Bindings: Env;
  Variables: Variables;
}> = async (c, next) => {
  const authHeader = c.req.header("Authorization");

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return c.json({ error: "Missing or invalid authorization header" }, 401);
  }

  const token = authHeader.substring(7); // Remove "Bearer " prefix

  try {
    // Verify the JWT token with Clerk
    const payload = await verifyToken(token, {
      secretKey: c.env.CLERK_SECRET_KEY,
    });

    if (!payload || !payload.sub) {
      return c.json({ error: "Invalid token" }, 401);
    }

    // Set user ID in context for downstream handlers
    c.set("userId", payload.sub);

    // Ensure user exists in database (upsert from JWT claims)
    await ensureUserExists(c.env.DB, payload);

    await next();
  } catch (error) {
    console.error("Auth error:", error);
    return c.json({ error: "Authentication failed" }, 401);
  }
};

/**
 * Get the authenticated user ID from context
 */
export function getUserId(c: Context<{ Variables: Variables }>): string {
  const userId = c.get("userId");
  if (!userId) {
    throw new Error("User ID not found in context");
  }
  return userId;
}

/**
 * Ensure user exists in database (create/update from JWT claims)
 */
async function ensureUserExists(db: D1Database, payload: any): Promise<void> {
  const now = Date.now();
  const userId = payload.sub;
  
  // Extract user info from JWT claims
  const email = payload.email || payload.primary_email_address || "";
  const displayName = payload.name || payload.first_name || payload.username || email.split("@")[0];
  
  try {
    // Check if user exists
    const existing = await db
      .prepare("SELECT id FROM users WHERE id = ?")
      .bind(userId)
      .first();

    if (!existing) {
      // Create new user
      await db
        .prepare(
          `INSERT INTO users (id, email, display_name, subscription_tier, created_at, updated_at)
           VALUES (?, ?, ?, 'free', ?, ?)`
        )
        .bind(userId, email, displayName, now, now)
        .run();
      
      console.log("Created new user:", { userId, email, displayName });
    } else {
      // Update existing user (in case email or name changed)
      await db
        .prepare(
          `UPDATE users SET email = ?, display_name = ?, updated_at = ? WHERE id = ?`
        )
        .bind(email, displayName, now, userId)
        .run();
    }
  } catch (error) {
    console.error("Error ensuring user exists:", error);
    // Don't fail the request if user creation fails
  }
}
