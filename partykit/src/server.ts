import type * as Party from "partykit/server";
import { onConnect, unstable_getYDoc } from "y-partykit";
import * as Y from "yjs";

/**
 * Writa Document Collaboration Server
 * 
 * Each PartyKit room represents one document.
 * Room ID format: "doc-{documentId}" (e.g., "doc-726C1513-0F88-4A54-9273-621A2327C59B")
 * 
 * Yjs Document Structure:
 * - ydoc.getXmlFragment('content')  → TipTap document content (synced automatically)
 * - ydoc.getMap('meta')             → Document metadata
 *   - meta.get('title')             → string
 *   - meta.get('isDeleted')         → boolean
 *   - meta.get('deletedAt')         → number (timestamp) or null
 *   - meta.get('workspaceId')       → string or null
 *   - meta.get('tags')              → Y.Array<string>
 *   - meta.get('isFavorite')        → boolean
 *   - meta.get('isPinned')          → boolean
 *   - meta.get('createdAt')         → number (timestamp)
 *   - meta.get('updatedAt')         → number (timestamp)
 */

export default class WritaDocumentServer implements Party.Server {
  constructor(readonly room: Party.Room) {}

  /**
   * Handle new WebSocket connections
   * y-partykit's onConnect handles all Yjs synchronization automatically
   */
  async onConnect(conn: Party.Connection, ctx: Party.ConnectionContext) {
    // Log connection for debugging
    const roomId = this.room.id;
    console.log(`[${roomId}] Client connected: ${conn.id}`);

    // Use y-partykit to handle Yjs sync
    // This automatically:
    // - Syncs document state to new clients
    // - Broadcasts updates to all connected clients
    // - Persists state to Durable Object storage
    return onConnect(conn, this.room, {
      persist: { mode: "snapshot" }
    });
  }

  /**
   * Handle messages from clients (if needed for custom commands)
   */
  async onMessage(message: string, sender: Party.Connection) {
    try {
      const data = JSON.parse(message);
      
      // Handle custom commands (e.g., explicit save request)
      if (data.type === "ping") {
        sender.send(JSON.stringify({ type: "pong" }));
      }
      
      // Handle metadata-only updates from native apps
      if (data.type === "updateMeta") {
        const ydoc = await unstable_getYDoc(this.room);
        if (ydoc) {
          const meta = ydoc.getMap("meta");
          ydoc.transact(() => {
            for (const [key, value] of Object.entries(data.meta)) {
              meta.set(key, value);
            }
            meta.set("updatedAt", Date.now());
          });
        }
      }
    } catch (e) {
      // Not JSON, ignore (Yjs binary messages are handled by y-partykit)
    }
  }

  /**
   * Handle client disconnection
   */
  async onClose(conn: Party.Connection) {
    console.log(`[${this.room.id}] Client disconnected: ${conn.id}`);
  }

  /**
   * Handle errors
   */
  async onError(conn: Party.Connection, error: Error) {
    console.error(`[${this.room.id}] Connection error:`, error);
  }

  /**
   * HTTP endpoint for document operations
   */
  async onRequest(req: Party.Request) {
    // CORS preflight
    if (req.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    // GET - Retrieve document info
    if (req.method === "GET") {
      const ydoc = await unstable_getYDoc(this.room);
      if (!ydoc) {
        return new Response(JSON.stringify({ error: "Document not found" }), {
          status: 404,
          headers: { "Content-Type": "application/json" },
        });
      }

      const meta = ydoc.getMap("meta");
      const content = ydoc.getXmlFragment("content");
      const plainText = getPlainTextFromYXml(content);

      return new Response(
        JSON.stringify({
          documentId: this.room.id.replace("doc-", ""),
          title: meta.get("title") || "",
          isDeleted: meta.get("isDeleted") || false,
          deletedAt: meta.get("deletedAt"),
          workspaceId: meta.get("workspaceId"),
          tags: meta.get("tags")?.toJSON?.() || [],
          isFavorite: meta.get("isFavorite") || false,
          isPinned: meta.get("isPinned") || false,
          createdAt: meta.get("createdAt"),
          updatedAt: meta.get("updatedAt"),
          wordCount: plainText.split(/\s+/).filter(Boolean).length,
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    // POST - Handle various actions
    if (req.method === "POST") {
      try {
        const body = await req.json() as { action?: string };

        // Reset document content (clears corrupted state)
        if (body.action === "reset") {
          const ydoc = await unstable_getYDoc(this.room);
          if (!ydoc) {
            return new Response(JSON.stringify({ error: "Document not found" }), {
              status: 404,
              headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            });
          }

          // Clear the content fragment and reinitialize with empty paragraph
          const content = ydoc.getXmlFragment("content");
          const meta = ydoc.getMap("meta");

          ydoc.transact(() => {
            // Delete all content
            while (content.length > 0) {
              content.delete(0, 1);
            }

            // Insert a fresh paragraph
            const paragraph = new Y.XmlElement("paragraph");
            content.insert(0, [paragraph]);

            // Update metadata
            meta.set("updatedAt", Date.now());
          });

          console.log(`[${this.room.id}] Document content reset`);

          return new Response(
            JSON.stringify({ success: true, message: "Document content reset" }),
            {
              status: 200,
              headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            }
          );
        }

        // Remove corrupted snippets
        if (body.action === "removeSnippets") {
          const ydoc = await unstable_getYDoc(this.room);
          if (!ydoc) {
            return new Response(JSON.stringify({ error: "Document not found" }), {
              status: 404,
              headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            });
          }

          const content = ydoc.getXmlFragment("content");
          let removedCount = 0;

          ydoc.transact(() => {
            // Find and remove promptSnippetList elements
            const toRemove: number[] = [];

            for (let i = 0; i < content.length; i++) {
              const child = content.get(i);
              if (child instanceof Y.XmlElement && child.nodeName === "promptSnippetList") {
                toRemove.push(i);
              }
            }

            // Remove in reverse order to maintain indices
            for (let i = toRemove.length - 1; i >= 0; i--) {
              content.delete(toRemove[i], 1);
              // Insert a paragraph to replace
              const paragraph = new Y.XmlElement("paragraph");
              content.insert(toRemove[i], [paragraph]);
              removedCount++;
            }

            if (removedCount > 0) {
              const meta = ydoc.getMap("meta");
              meta.set("updatedAt", Date.now());
            }
          });

          console.log(`[${this.room.id}] Removed ${removedCount} snippet lists`);

          return new Response(
            JSON.stringify({ success: true, removed: removedCount }),
            {
              status: 200,
              headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            }
          );
        }

        return new Response(JSON.stringify({ error: "Unknown action" }), {
          status: 400,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
          status: 400,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }
    }

    return new Response("Method not allowed", { status: 405 });
  }
}

/**
 * Extract plain text from Yjs XmlFragment (TipTap content)
 */
function getPlainTextFromYXml(xml: Y.XmlFragment): string {
  let text = "";
  
  const extractText = (node: Y.XmlElement | Y.XmlText | Y.XmlFragment) => {
    if (node instanceof Y.XmlText) {
      text += node.toString();
    } else if (node instanceof Y.XmlElement || node instanceof Y.XmlFragment) {
      // Add newline after block elements
      const isBlock = node instanceof Y.XmlElement && 
        ["paragraph", "heading", "blockquote", "listItem", "taskItem"].includes(node.nodeName);
      
      for (const child of node.toArray()) {
        extractText(child as Y.XmlElement | Y.XmlText);
      }
      
      if (isBlock) {
        text += "\n";
      }
    }
  };
  
  extractText(xml);
  return text.trim();
}

// Export for PartyKit
WritaDocumentServer satisfies Party.Worker;
