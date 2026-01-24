/**
 * Upload Routes
 *
 * File upload handling with R2 storage.
 */

import { Hono } from "hono";
import type { Env, Variables } from "../index";
import { getUserId } from "../middleware/auth";

export const uploadRoutes = new Hono<{
  Bindings: Env;
  Variables: Variables;
}>();

// Allowed file types
const ALLOWED_TYPES = [
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
  "image/svg+xml",
];

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

// POST /api/upload - Upload a file
uploadRoutes.post("/", async (c) => {
  const userId = getUserId(c);

  try {
    const contentType = c.req.header("Content-Type");

    if (contentType?.includes("multipart/form-data")) {
      // Handle multipart form upload
      const formData = await c.req.formData();
      const file = formData.get("file") as File | null;

      if (!file) {
        return c.json({ error: "No file provided" }, 400);
      }

      // Validate file type
      if (!ALLOWED_TYPES.includes(file.type)) {
        return c.json(
          {
            error: "Invalid file type",
            allowed: ALLOWED_TYPES,
          },
          400
        );
      }

      // Validate file size
      if (file.size > MAX_FILE_SIZE) {
        return c.json(
          {
            error: "File too large",
            maxSize: MAX_FILE_SIZE,
          },
          400
        );
      }

      // Generate unique key
      const extension = getExtension(file.type);
      const key = `${userId}/${crypto.randomUUID()}.${extension}`;

      // Upload to R2
      await c.env.R2_BUCKET.put(key, file.stream(), {
        httpMetadata: {
          contentType: file.type,
        },
        customMetadata: {
          userId,
          originalName: file.name,
          uploadedAt: new Date().toISOString(),
        },
      });

      // Return the URL
      // Note: You'll need to set up a public URL or custom domain for R2
      return c.json({
        success: true,
        key,
        url: `/api/files/${key}`,
        contentType: file.type,
        size: file.size,
      });
    } else {
      // Handle raw body upload
      const body = await c.req.arrayBuffer();

      if (body.byteLength === 0) {
        return c.json({ error: "Empty file" }, 400);
      }

      if (body.byteLength > MAX_FILE_SIZE) {
        return c.json({ error: "File too large" }, 400);
      }

      // Get content type from header
      const fileType = contentType || "application/octet-stream";

      // Generate unique key
      const extension = getExtension(fileType);
      const key = `${userId}/${crypto.randomUUID()}.${extension}`;

      // Upload to R2
      await c.env.R2_BUCKET.put(key, body, {
        httpMetadata: {
          contentType: fileType,
        },
        customMetadata: {
          userId,
          uploadedAt: new Date().toISOString(),
        },
      });

      return c.json({
        success: true,
        key,
        url: `/api/files/${key}`,
        contentType: fileType,
        size: body.byteLength,
      });
    }
  } catch (error) {
    console.error("Upload error:", error);
    return c.json({ error: "Failed to upload file" }, 500);
  }
});

// GET /api/upload/:key - Get file (proxy from R2)
uploadRoutes.get("/:userId/:fileId", async (c) => {
  const requestingUserId = getUserId(c);
  const fileUserId = c.req.param("userId");
  const fileId = c.req.param("fileId");

  // Only allow access to own files (can be extended for shared files)
  if (requestingUserId !== fileUserId) {
    return c.json({ error: "Access denied" }, 403);
  }

  const key = `${fileUserId}/${fileId}`;

  try {
    const object = await c.env.R2_BUCKET.get(key);

    if (!object) {
      return c.json({ error: "File not found" }, 404);
    }

    const headers = new Headers();
    headers.set(
      "Content-Type",
      object.httpMetadata?.contentType || "application/octet-stream"
    );
    headers.set("Cache-Control", "public, max-age=31536000"); // Cache for 1 year

    return new Response(object.body, { headers });
  } catch (error) {
    console.error("File retrieval error:", error);
    return c.json({ error: "Failed to retrieve file" }, 500);
  }
});

// DELETE /api/upload/:key - Delete file
uploadRoutes.delete("/:userId/:fileId", async (c) => {
  const requestingUserId = getUserId(c);
  const fileUserId = c.req.param("userId");
  const fileId = c.req.param("fileId");

  // Only allow deletion of own files
  if (requestingUserId !== fileUserId) {
    return c.json({ error: "Access denied" }, 403);
  }

  const key = `${fileUserId}/${fileId}`;

  try {
    await c.env.R2_BUCKET.delete(key);
    return c.json({ success: true });
  } catch (error) {
    console.error("File deletion error:", error);
    return c.json({ error: "Failed to delete file" }, 500);
  }
});

// Helper to get file extension from content type
function getExtension(contentType: string): string {
  const map: Record<string, string> = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp",
    "image/svg+xml": "svg",
    "application/pdf": "pdf",
  };

  return map[contentType] || "bin";
}
