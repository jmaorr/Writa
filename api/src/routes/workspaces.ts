/**
 * Workspace Routes
 *
 * CRUD operations for workspaces.
 */

import { Hono } from "hono";
import type { Env, Variables } from "../index";
import { getUserId } from "../middleware/auth";

export const workspaceRoutes = new Hono<{
  Bindings: Env;
  Variables: Variables;
}>();

// Types
interface Workspace {
  id: string;
  user_id: string;
  name: string;
  icon: string;
  color: string;
  sort_order: number;
  parent_id: string | null;
  is_expanded: number;
  version: number;
  created_at: number;
  updated_at: number;
}

interface CreateWorkspaceRequest {
  id: string;
  name: string;
  icon?: string;
  color?: string;
  sortOrder?: number;
  parentId?: string;
  isExpanded?: boolean;
}

interface UpdateWorkspaceRequest {
  name?: string;
  icon?: string;
  color?: string;
  sortOrder?: number;
  parentId?: string | null;
  isExpanded?: boolean;
}

// GET /api/workspaces - List all workspaces
workspaceRoutes.get("/", async (c) => {
  const userId = getUserId(c);

  try {
    const result = await c.env.DB.prepare(
      `SELECT * FROM workspaces WHERE user_id = ? ORDER BY sort_order ASC`
    )
      .bind(userId)
      .all<Workspace>();

    const workspaces = result.results.map(transformWorkspace);

    return c.json({ workspaces });
  } catch (error) {
    console.error("Error listing workspaces:", error);
    return c.json({ error: "Failed to list workspaces" }, 500);
  }
});

// GET /api/workspaces/:id - Get single workspace
workspaceRoutes.get("/:id", async (c) => {
  const userId = getUserId(c);
  const workspaceId = c.req.param("id");

  try {
    const result = await c.env.DB.prepare(
      `SELECT * FROM workspaces WHERE id = ? AND user_id = ?`
    )
      .bind(workspaceId, userId)
      .first<Workspace>();

    if (!result) {
      return c.json({ error: "Workspace not found" }, 404);
    }

    return c.json({ workspace: transformWorkspace(result) });
  } catch (error) {
    console.error("Error getting workspace:", error);
    return c.json({ error: "Failed to get workspace" }, 500);
  }
});

// POST /api/workspaces - Create workspace
workspaceRoutes.post("/", async (c) => {
  const userId = getUserId(c);
  const body = await c.req.json<CreateWorkspaceRequest>();

  const now = Date.now();

  try {
    await c.env.DB.prepare(
      `
      INSERT INTO workspaces (
        id, user_id, name, icon, color, sort_order, parent_id, is_expanded,
        version, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `
    )
      .bind(
        body.id,
        userId,
        body.name,
        body.icon || "folder",
        body.color || "systemBlue",
        body.sortOrder || 0,
        body.parentId || null,
        body.isExpanded !== false ? 1 : 0,
        now,
        now
      )
      .run();

    return c.json(
      {
        success: true,
        workspace: {
          id: body.id,
          version: 1,
          createdAt: now,
          updatedAt: now,
        },
      },
      201
    );
  } catch (error) {
    console.error("Error creating workspace:", error);
    return c.json({ error: "Failed to create workspace" }, 500);
  }
});

// PUT /api/workspaces/:id - Update workspace
workspaceRoutes.put("/:id", async (c) => {
  const userId = getUserId(c);
  const workspaceId = c.req.param("id");
  const body = await c.req.json<UpdateWorkspaceRequest>();

  try {
    // Get current workspace to check version
    const current = await c.env.DB.prepare(
      `SELECT version FROM workspaces WHERE id = ? AND user_id = ?`
    )
      .bind(workspaceId, userId)
      .first<{ version: number }>();

    if (!current) {
      return c.json({ error: "Workspace not found" }, 404);
    }

    const newVersion = current.version + 1;
    const now = Date.now();

    // Build dynamic update query
    const updates: string[] = [];
    const values: any[] = [];

    if (body.name !== undefined) {
      updates.push("name = ?");
      values.push(body.name);
    }
    if (body.icon !== undefined) {
      updates.push("icon = ?");
      values.push(body.icon);
    }
    if (body.color !== undefined) {
      updates.push("color = ?");
      values.push(body.color);
    }
    if (body.sortOrder !== undefined) {
      updates.push("sort_order = ?");
      values.push(body.sortOrder);
    }
    if (body.parentId !== undefined) {
      updates.push("parent_id = ?");
      values.push(body.parentId);
    }
    if (body.isExpanded !== undefined) {
      updates.push("is_expanded = ?");
      values.push(body.isExpanded ? 1 : 0);
    }

    // Always update version and timestamp
    updates.push("version = ?", "updated_at = ?");
    values.push(newVersion, now, workspaceId, userId);

    await c.env.DB.prepare(
      `UPDATE workspaces SET ${updates.join(", ")} WHERE id = ? AND user_id = ?`
    )
      .bind(...values)
      .run();

    return c.json({
      success: true,
      workspace: { id: workspaceId, version: newVersion, updatedAt: now },
    });
  } catch (error) {
    console.error("Error updating workspace:", error);
    return c.json({ error: "Failed to update workspace" }, 500);
  }
});

// DELETE /api/workspaces/:id - Delete workspace
workspaceRoutes.delete("/:id", async (c) => {
  const userId = getUserId(c);
  const workspaceId = c.req.param("id");

  try {
    // First, unassign all documents from this workspace
    await c.env.DB.prepare(
      `UPDATE documents SET workspace_id = NULL, updated_at = ? WHERE workspace_id = ? AND user_id = ?`
    )
      .bind(Date.now(), workspaceId, userId)
      .run();

    // Move child workspaces to parent (or make them root)
    const workspace = await c.env.DB.prepare(
      `SELECT parent_id FROM workspaces WHERE id = ? AND user_id = ?`
    )
      .bind(workspaceId, userId)
      .first<{ parent_id: string | null }>();

    if (workspace) {
      await c.env.DB.prepare(
        `UPDATE workspaces SET parent_id = ?, updated_at = ? WHERE parent_id = ? AND user_id = ?`
      )
        .bind(workspace.parent_id, Date.now(), workspaceId, userId)
        .run();
    }

    // Delete the workspace
    await c.env.DB.prepare(
      `DELETE FROM workspaces WHERE id = ? AND user_id = ?`
    )
      .bind(workspaceId, userId)
      .run();

    return c.json({ success: true });
  } catch (error) {
    console.error("Error deleting workspace:", error);
    return c.json({ error: "Failed to delete workspace" }, 500);
  }
});

// Helper to transform DB row to API response
function transformWorkspace(row: Workspace) {
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
