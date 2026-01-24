/**
 * Sync Routes
 *
 * Batch sync endpoint for efficient data synchronization.
 * Supports pulling changes since a timestamp and pushing local changes.
 */

import { Hono } from "hono";
import type { Env, Variables } from "../index";
import { getUserId } from "../middleware/auth";

export const syncRoutes = new Hono<{
  Bindings: Env;
  Variables: Variables;
}>();

// Types
interface SyncPullRequest {
  since?: number; // Timestamp in milliseconds
  includeDeleted?: boolean;
}

interface SyncPushRequest {
  documents?: DocumentChange[];
  workspaces?: WorkspaceChange[];
  settings?: SettingsChange;
}

interface DocumentChange {
  id: string;
  title: string;
  summary?: string;
  content?: string;
  plain_text?: string;  // snake_case from iOS
  word_count?: number;  // snake_case from iOS
  workspace_id?: string | null;  // snake_case from iOS
  tags?: string[];
  is_favorite?: boolean;  // snake_case from iOS
  is_pinned?: boolean;  // snake_case from iOS
  is_deleted?: boolean;  // snake_case from iOS
  deleted_at?: number | null;  // snake_case from iOS
  version: number;
  created_at: number;  // snake_case from iOS
  updated_at: number;  // snake_case from iOS
}

interface WorkspaceChange {
  id: string;
  name: string;
  icon: string;
  color: string;
  sort_order: number;  // snake_case from iOS
  parent_id?: string | null;  // snake_case from iOS
  is_expanded: boolean;  // snake_case from iOS
  version: number;
  created_at: number;  // snake_case from iOS
  updated_at: number;  // snake_case from iOS
}

interface SettingsChange {
  settings: Record<string, any>;
  version: number;
  updatedAt: number;
}

// GET /api/sync?since=<timestamp> - Pull changes since timestamp
syncRoutes.get("/", async (c) => {
  const userId = getUserId(c);
  const since = parseInt(c.req.query("since") || "0");
  const includeDeleted = c.req.query("includeDeleted") === "true";

  try {
    // Get documents changed since timestamp
    let documentQuery = `
      SELECT * FROM documents 
      WHERE user_id = ? AND updated_at > ?
    `;
    if (!includeDeleted) {
      documentQuery += ` AND is_deleted = 0`;
    }

    const documents = await c.env.DB.prepare(documentQuery)
      .bind(userId, since)
      .all();

    // Get workspaces changed since timestamp
    const workspaces = await c.env.DB.prepare(
      `SELECT * FROM workspaces WHERE user_id = ? AND updated_at > ?`
    )
      .bind(userId, since)
      .all();

    // Get settings if changed since timestamp
    const settings = await c.env.DB.prepare(
      `SELECT * FROM user_settings WHERE user_id = ? AND updated_at > ?`
    )
      .bind(userId, since)
      .first();

    // Get deleted document IDs (for clients to remove)
    const deletedDocs = await c.env.DB.prepare(
      `SELECT id FROM documents WHERE user_id = ? AND is_deleted = 1 AND updated_at > ?`
    )
      .bind(userId, since)
      .all();

    return c.json({
      documents: documents.results.map(transformDocument),
      workspaces: workspaces.results.map(transformWorkspace),
      settings: settings
        ? {
            settings: JSON.parse((settings as any).settings),
            version: (settings as any).version,
            updatedAt: (settings as any).updated_at,
          }
        : null,
      deletedDocumentIds: deletedDocs.results.map((d: any) => d.id),
      serverTime: Date.now(),
    });
  } catch (error) {
    console.error("Error pulling sync:", error);
    return c.json({ error: "Failed to pull changes" }, 500);
  }
});

// POST /api/sync - Push local changes
syncRoutes.post("/", async (c) => {
  const userId = getUserId(c);
  const body = await c.req.json<SyncPushRequest>();
  
  console.log("Sync push request received:", {
    documentsCount: body.documents?.length || 0,
    workspacesCount: body.workspaces?.length || 0,
    workspaces: body.workspaces
  });

  const results = {
    documents: [] as { id: string; version: number; status: string }[],
    workspaces: [] as { id: string; version: number; status: string }[],
    settings: null as { version: number; status: string } | null,
    conflicts: [] as { type: string; id: string; serverVersion: number }[],
  };

  try {
    // Process documents
    if (body.documents?.length) {
      for (const doc of body.documents) {
        const result = await syncDocument(c.env.DB, userId, doc);
        if (result.conflict) {
          results.conflicts.push({
            type: "document",
            id: doc.id,
            serverVersion: result.serverVersion!,
          });
        } else {
          results.documents.push({
            id: doc.id,
            version: result.version,
            status: result.status,
          });
        }
      }
    }

    // Process workspaces
    if (body.workspaces?.length) {
      for (const ws of body.workspaces) {
        const result = await syncWorkspace(c.env.DB, userId, ws);
        if (result.conflict) {
          results.conflicts.push({
            type: "workspace",
            id: ws.id,
            serverVersion: result.serverVersion!,
          });
        } else {
          results.workspaces.push({
            id: ws.id,
            version: result.version,
            status: result.status,
          });
        }
      }
    }

    // Process settings
    if (body.settings) {
      const result = await syncSettings(c.env.DB, userId, body.settings);
      results.settings = {
        version: result.version,
        status: result.status,
      };
    }

    return c.json({
      success: true,
      results,
      serverTime: Date.now(),
    });
  } catch (error) {
    console.error("Error pushing sync:", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return c.json({ 
      error: "Failed to push changes", 
      details: errorMessage,
      stack: error instanceof Error ? error.stack : undefined
    }, 500);
  }
});

// Helper functions for syncing individual items

async function syncDocument(
  db: D1Database,
  userId: string,
  doc: DocumentChange
): Promise<{
  status: string;
  version: number;
  conflict?: boolean;
  serverVersion?: number;
}> {
  const now = Date.now();

  // Check if document exists
  const existing = await db
    .prepare(`SELECT version FROM documents WHERE id = ? AND user_id = ?`)
    .bind(doc.id, userId)
    .first<{ version: number }>();

  if (existing) {
    // Check for conflict (client version must be >= server version - 1)
    if (doc.version < existing.version) {
      return { status: "conflict", version: existing.version, conflict: true, serverVersion: existing.version };
    }

    // Update
    const newVersion = existing.version + 1;
    await db
      .prepare(
        `
        UPDATE documents SET 
          title = ?, summary = ?, content = ?, plain_text = ?, word_count = ?,
          workspace_id = ?, tags = ?, is_favorite = ?, is_pinned = ?,
          is_deleted = ?, deleted_at = ?, version = ?, updated_at = ?
        WHERE id = ? AND user_id = ?
      `
      )
      .bind(
        doc.title,
        doc.summary || null,
        doc.content || null,
        doc.plain_text || "",
        doc.word_count || 0,
        doc.workspace_id || null,
        JSON.stringify(doc.tags || []),
        doc.is_favorite ? 1 : 0,
        doc.is_pinned ? 1 : 0,
        doc.is_deleted ? 1 : 0,
        doc.deleted_at || null,
        newVersion,
        now,
        doc.id,
        userId
      )
      .run();

    return { status: "updated", version: newVersion };
  } else {
    // Create
    await db
      .prepare(
        `
        INSERT INTO documents (
          id, user_id, title, summary, content, plain_text, word_count,
          workspace_id, tags, is_favorite, is_pinned, is_deleted, deleted_at,
          version, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
      `
      )
      .bind(
        doc.id,
        userId,
        doc.title,
        doc.summary || null,
        doc.content || null,
        doc.plain_text || "",
        doc.word_count || 0,
        doc.workspace_id || null,
        JSON.stringify(doc.tags || []),
        doc.is_favorite ? 1 : 0,
        doc.is_pinned ? 1 : 0,
        doc.is_deleted ? 1 : 0,
        doc.deleted_at || null,
        doc.created_at || now,
        now
      )
      .run();

    return { status: "created", version: 1 };
  }
}

async function syncWorkspace(
  db: D1Database,
  userId: string,
  ws: WorkspaceChange
): Promise<{
  status: string;
  version: number;
  conflict?: boolean;
  serverVersion?: number;
}> {
  try {
    console.log("Syncing workspace:", { id: ws.id, name: ws.name, userId });
    const now = Date.now();

    // Check if workspace exists
    const existing = await db
      .prepare(`SELECT version FROM workspaces WHERE id = ? AND user_id = ?`)
      .bind(ws.id, userId)
      .first<{ version: number }>();

    if (existing) {
      // Check for conflict
      if (ws.version < existing.version) {
        return { status: "conflict", version: existing.version, conflict: true, serverVersion: existing.version };
      }

      // Update
      const newVersion = existing.version + 1;
      console.log("Updating workspace:", ws.id);
      await db
        .prepare(
          `
          UPDATE workspaces SET 
            name = ?, icon = ?, color = ?, sort_order = ?, parent_id = ?,
            is_expanded = ?, version = ?, updated_at = ?
          WHERE id = ? AND user_id = ?
        `
        )
        .bind(
          ws.name,
          ws.icon,
          ws.color,
          ws.sort_order,
          ws.parent_id || null,
          ws.is_expanded ? 1 : 0,
          newVersion,
          now,
          ws.id,
          userId
        )
        .run();

      return { status: "updated", version: newVersion };
    } else {
      // Create
      console.log("Creating new workspace:", { 
        id: ws.id, 
        name: ws.name,
        icon: ws.icon,
        color: ws.color,
        sort_order: ws.sort_order,
        parent_id: ws.parent_id,
        is_expanded: ws.is_expanded,
        version: ws.version,
        created_at: ws.created_at,
        updated_at: ws.updated_at
      });
      
      // Prepare bind values
      const bindValues = [
        ws.id,
        userId,
        ws.name,
        ws.icon,
        ws.color,
        ws.sort_order,
        ws.parent_id || null,
        ws.is_expanded ? 1 : 0,
        ws.created_at || now,
        now
      ];
      
      console.log("Bind values:", bindValues);
      
      const result = await db
        .prepare(
          `
          INSERT INTO workspaces (
            id, user_id, name, icon, color, sort_order, parent_id,
            is_expanded, version, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
        `
        )
        .bind(...bindValues)
        .run();

      console.log("Workspace created:", result);
      return { status: "created", version: 1 };
    }
  } catch (error) {
    console.error("Error in syncWorkspace:", error, "Workspace data:", ws);
    throw error;
  }
}

async function syncSettings(
  db: D1Database,
  userId: string,
  settings: SettingsChange
): Promise<{ status: string; version: number }> {
  const now = Date.now();
  const settingsJson = JSON.stringify(settings.settings);

  // Check if settings exist
  const existing = await db
    .prepare(`SELECT version FROM user_settings WHERE user_id = ?`)
    .bind(userId)
    .first<{ version: number }>();

  if (existing) {
    const newVersion = existing.version + 1;
    await db
      .prepare(
        `UPDATE user_settings SET settings = ?, version = ?, updated_at = ? WHERE user_id = ?`
      )
      .bind(settingsJson, newVersion, now, userId)
      .run();

    return { status: "updated", version: newVersion };
  } else {
    await db
      .prepare(
        `INSERT INTO user_settings (user_id, settings, version, updated_at) VALUES (?, ?, 1, ?)`
      )
      .bind(userId, settingsJson, now)
      .run();

    return { status: "created", version: 1 };
  }
}

// Transform helpers
function transformDocument(row: any) {
  return {
    id: row.id,
    title: row.title,
    summary: row.summary,
    content: row.content,
    plainText: row.plain_text,
    wordCount: row.word_count,
    workspaceId: row.workspace_id,
    tags: JSON.parse(row.tags || "[]"),
    isFavorite: row.is_favorite === 1,
    isPinned: row.is_pinned === 1,
    isDeleted: row.is_deleted === 1,
    deletedAt: row.deleted_at,
    version: row.version,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function transformWorkspace(row: any) {
  return {
    id: row.id,
    name: row.name,
    icon: row.icon,
    color: row.color,
    sortOrder: row.sort_order,
    parentId: row.parent_id,
    isExpanded: row.is_expanded === 1,
    version: row.version,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
