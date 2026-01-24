/**
 * Document Routes
 *
 * CRUD operations for documents.
 */

import { Hono } from "hono";
import type { Env, Variables } from "../index";
import { getUserId } from "../middleware/auth";

export const documentRoutes = new Hono<{
  Bindings: Env;
  Variables: Variables;
}>();

// Types
interface Document {
  id: string;
  user_id: string;
  title: string;
  summary: string | null;
  content: string | null;
  plain_text: string;
  word_count: number;
  workspace_id: string | null;
  tags: string;
  is_favorite: number;
  is_pinned: number;
  is_deleted: number;
  deleted_at: number | null;
  version: number;
  created_at: number;
  updated_at: number;
}

interface CreateDocumentRequest {
  id: string;
  title: string;
  summary?: string;
  content?: string;
  plainText?: string;
  wordCount?: number;
  workspaceId?: string;
  tags?: string[];
  isFavorite?: boolean;
  isPinned?: boolean;
}

interface UpdateDocumentRequest {
  title?: string;
  summary?: string;
  content?: string;
  plainText?: string;
  wordCount?: number;
  workspaceId?: string | null;
  tags?: string[];
  isFavorite?: boolean;
  isPinned?: boolean;
  isDeleted?: boolean;
  deletedAt?: number | null;
}

// GET /api/documents - List all documents
documentRoutes.get("/", async (c) => {
  const userId = getUserId(c);
  const includeDeleted = c.req.query("includeDeleted") === "true";

  try {
    let query = `
      SELECT * FROM documents 
      WHERE user_id = ?
    `;

    if (!includeDeleted) {
      query += ` AND is_deleted = 0`;
    }

    query += ` ORDER BY updated_at DESC`;

    const result = await c.env.DB.prepare(query).bind(userId).all<Document>();

    const documents = result.results.map(transformDocument);

    return c.json({ documents });
  } catch (error) {
    console.error("Error listing documents:", error);
    return c.json({ error: "Failed to list documents" }, 500);
  }
});

// GET /api/documents/:id - Get single document
documentRoutes.get("/:id", async (c) => {
  const userId = getUserId(c);
  const documentId = c.req.param("id");

  try {
    const result = await c.env.DB.prepare(
      `SELECT * FROM documents WHERE id = ? AND user_id = ?`
    )
      .bind(documentId, userId)
      .first<Document>();

    if (!result) {
      return c.json({ error: "Document not found" }, 404);
    }

    return c.json({ document: transformDocument(result) });
  } catch (error) {
    console.error("Error getting document:", error);
    return c.json({ error: "Failed to get document" }, 500);
  }
});

// POST /api/documents - Create document
documentRoutes.post("/", async (c) => {
  const userId = getUserId(c);
  const body = await c.req.json<CreateDocumentRequest>();

  const now = Date.now();

  try {
    await c.env.DB.prepare(
      `
      INSERT INTO documents (
        id, user_id, title, summary, content, plain_text, word_count,
        workspace_id, tags, is_favorite, is_pinned, is_deleted, deleted_at,
        version, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NULL, 1, ?, ?)
    `
    )
      .bind(
        body.id,
        userId,
        body.title,
        body.summary || null,
        body.content || null,
        body.plainText || "",
        body.wordCount || 0,
        body.workspaceId || null,
        JSON.stringify(body.tags || []),
        body.isFavorite ? 1 : 0,
        body.isPinned ? 1 : 0,
        now,
        now
      )
      .run();

    return c.json(
      {
        success: true,
        document: {
          id: body.id,
          version: 1,
          createdAt: now,
          updatedAt: now,
        },
      },
      201
    );
  } catch (error) {
    console.error("Error creating document:", error);
    return c.json({ error: "Failed to create document" }, 500);
  }
});

// PUT /api/documents/:id - Update document
documentRoutes.put("/:id", async (c) => {
  const userId = getUserId(c);
  const documentId = c.req.param("id");
  const body = await c.req.json<UpdateDocumentRequest>();

  try {
    // Get current document to check version
    const current = await c.env.DB.prepare(
      `SELECT version FROM documents WHERE id = ? AND user_id = ?`
    )
      .bind(documentId, userId)
      .first<{ version: number }>();

    if (!current) {
      return c.json({ error: "Document not found" }, 404);
    }

    const newVersion = current.version + 1;
    const now = Date.now();

    // Build dynamic update query
    const updates: string[] = [];
    const values: any[] = [];

    if (body.title !== undefined) {
      updates.push("title = ?");
      values.push(body.title);
    }
    if (body.summary !== undefined) {
      updates.push("summary = ?");
      values.push(body.summary);
    }
    if (body.content !== undefined) {
      updates.push("content = ?");
      values.push(body.content);
    }
    if (body.plainText !== undefined) {
      updates.push("plain_text = ?");
      values.push(body.plainText);
    }
    if (body.wordCount !== undefined) {
      updates.push("word_count = ?");
      values.push(body.wordCount);
    }
    if (body.workspaceId !== undefined) {
      updates.push("workspace_id = ?");
      values.push(body.workspaceId);
    }
    if (body.tags !== undefined) {
      updates.push("tags = ?");
      values.push(JSON.stringify(body.tags));
    }
    if (body.isFavorite !== undefined) {
      updates.push("is_favorite = ?");
      values.push(body.isFavorite ? 1 : 0);
    }
    if (body.isPinned !== undefined) {
      updates.push("is_pinned = ?");
      values.push(body.isPinned ? 1 : 0);
    }
    if (body.isDeleted !== undefined) {
      updates.push("is_deleted = ?");
      values.push(body.isDeleted ? 1 : 0);
    }
    if (body.deletedAt !== undefined) {
      updates.push("deleted_at = ?");
      values.push(body.deletedAt);
    }

    // Always update version and timestamp
    updates.push("version = ?", "updated_at = ?");
    values.push(newVersion, now, documentId, userId);

    await c.env.DB.prepare(
      `UPDATE documents SET ${updates.join(", ")} WHERE id = ? AND user_id = ?`
    )
      .bind(...values)
      .run();

    return c.json({
      success: true,
      document: { id: documentId, version: newVersion, updatedAt: now },
    });
  } catch (error) {
    console.error("Error updating document:", error);
    return c.json({ error: "Failed to update document" }, 500);
  }
});

// DELETE /api/documents/:id - Soft delete document
documentRoutes.delete("/:id", async (c) => {
  const userId = getUserId(c);
  const documentId = c.req.param("id");
  const permanent = c.req.query("permanent") === "true";

  try {
    if (permanent) {
      // Permanent delete
      await c.env.DB.prepare(
        `DELETE FROM documents WHERE id = ? AND user_id = ?`
      )
        .bind(documentId, userId)
        .run();
    } else {
      // Soft delete
      const now = Date.now();
      await c.env.DB.prepare(
        `UPDATE documents SET is_deleted = 1, deleted_at = ?, updated_at = ? WHERE id = ? AND user_id = ?`
      )
        .bind(now, now, documentId, userId)
        .run();
    }

    return c.json({ success: true });
  } catch (error) {
    console.error("Error deleting document:", error);
    return c.json({ error: "Failed to delete document" }, 500);
  }
});

// Helper to transform DB row to API response
function transformDocument(row: Document) {
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
