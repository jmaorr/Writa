-- Writa Database Schema
-- Initial migration for D1

-- Users table (synced from Clerk)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,              -- Clerk user ID
  email TEXT NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  subscription_tier TEXT DEFAULT 'free',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,              -- UUID from client
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT,
  content TEXT,                     -- ProseMirror JSON
  plain_text TEXT DEFAULT '',
  word_count INTEGER DEFAULT 0,
  workspace_id TEXT,
  tags TEXT DEFAULT '[]',           -- JSON array
  is_favorite INTEGER DEFAULT 0,
  is_pinned INTEGER DEFAULT 0,
  is_deleted INTEGER DEFAULT 0,
  deleted_at INTEGER,
  version INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_documents_user ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_workspace ON documents(workspace_id);
CREATE INDEX IF NOT EXISTS idx_documents_updated ON documents(updated_at);
CREATE INDEX IF NOT EXISTS idx_documents_deleted ON documents(user_id, is_deleted);

-- Workspaces table
CREATE TABLE IF NOT EXISTS workspaces (
  id TEXT PRIMARY KEY,              -- UUID from client
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  icon TEXT DEFAULT 'folder',
  color TEXT DEFAULT 'systemBlue',
  sort_order INTEGER DEFAULT 0,
  parent_id TEXT,
  is_expanded INTEGER DEFAULT 1,
  version INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES workspaces(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_workspaces_user ON workspaces(user_id);
CREATE INDEX IF NOT EXISTS idx_workspaces_parent ON workspaces(parent_id);
CREATE INDEX IF NOT EXISTS idx_workspaces_updated ON workspaces(updated_at);

-- User Settings table
CREATE TABLE IF NOT EXISTS user_settings (
  user_id TEXT PRIMARY KEY,
  settings TEXT NOT NULL DEFAULT '{}',  -- JSON blob
  version INTEGER DEFAULT 1,
  updated_at INTEGER NOT NULL
);
