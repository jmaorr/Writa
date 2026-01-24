/**
 * Settings Routes
 *
 * User settings storage and retrieval.
 */

import { Hono } from "hono";
import type { Env, Variables } from "../index";
import { getUserId } from "../middleware/auth";

export const settingsRoutes = new Hono<{
  Bindings: Env;
  Variables: Variables;
}>();

// Types
interface UserSettings {
  user_id: string;
  settings: string;
  version: number;
  updated_at: number;
}

interface UpdateSettingsRequest {
  settings: Record<string, any>;
  version?: number;
}

// GET /api/settings - Get user settings
settingsRoutes.get("/", async (c) => {
  const userId = getUserId(c);

  try {
    const result = await c.env.DB.prepare(
      `SELECT * FROM user_settings WHERE user_id = ?`
    )
      .bind(userId)
      .first<UserSettings>();

    if (!result) {
      // Return empty settings if none exist
      return c.json({
        settings: {},
        version: 0,
        updatedAt: null,
      });
    }

    return c.json({
      settings: JSON.parse(result.settings),
      version: result.version,
      updatedAt: result.updated_at,
    });
  } catch (error) {
    console.error("Error getting settings:", error);
    return c.json({ error: "Failed to get settings" }, 500);
  }
});

// PUT /api/settings - Update user settings
settingsRoutes.put("/", async (c) => {
  const userId = getUserId(c);
  const body = await c.req.json<UpdateSettingsRequest>();

  const now = Date.now();
  const settingsJson = JSON.stringify(body.settings);

  try {
    // Check if settings exist
    const existing = await c.env.DB.prepare(
      `SELECT version FROM user_settings WHERE user_id = ?`
    )
      .bind(userId)
      .first<{ version: number }>();

    if (existing) {
      // Update existing settings
      const newVersion = existing.version + 1;

      await c.env.DB.prepare(
        `UPDATE user_settings SET settings = ?, version = ?, updated_at = ? WHERE user_id = ?`
      )
        .bind(settingsJson, newVersion, now, userId)
        .run();

      return c.json({
        success: true,
        version: newVersion,
        updatedAt: now,
      });
    } else {
      // Create new settings
      await c.env.DB.prepare(
        `INSERT INTO user_settings (user_id, settings, version, updated_at) VALUES (?, ?, 1, ?)`
      )
        .bind(userId, settingsJson, now)
        .run();

      return c.json({
        success: true,
        version: 1,
        updatedAt: now,
      });
    }
  } catch (error) {
    console.error("Error updating settings:", error);
    return c.json({ error: "Failed to update settings" }, 500);
  }
});

// PATCH /api/settings - Partial update (merge with existing)
settingsRoutes.patch("/", async (c) => {
  const userId = getUserId(c);
  const body = await c.req.json<UpdateSettingsRequest>();

  const now = Date.now();

  try {
    // Get existing settings
    const existing = await c.env.DB.prepare(
      `SELECT settings, version FROM user_settings WHERE user_id = ?`
    )
      .bind(userId)
      .first<{ settings: string; version: number }>();

    let currentSettings = {};
    let currentVersion = 0;

    if (existing) {
      currentSettings = JSON.parse(existing.settings);
      currentVersion = existing.version;
    }

    // Merge settings
    const mergedSettings = {
      ...currentSettings,
      ...body.settings,
    };

    const settingsJson = JSON.stringify(mergedSettings);
    const newVersion = currentVersion + 1;

    if (existing) {
      await c.env.DB.prepare(
        `UPDATE user_settings SET settings = ?, version = ?, updated_at = ? WHERE user_id = ?`
      )
        .bind(settingsJson, newVersion, now, userId)
        .run();
    } else {
      await c.env.DB.prepare(
        `INSERT INTO user_settings (user_id, settings, version, updated_at) VALUES (?, ?, 1, ?)`
      )
        .bind(userId, settingsJson, now)
        .run();
    }

    return c.json({
      success: true,
      settings: mergedSettings,
      version: newVersion,
      updatedAt: now,
    });
  } catch (error) {
    console.error("Error patching settings:", error);
    return c.json({ error: "Failed to update settings" }, 500);
  }
});
