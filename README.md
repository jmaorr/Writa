# Writa

A native, cross-platform writing application with a powerful content library and embedded rich text editor.

## Overview

Writa is designed for Product, Design, and Engineering teams to create, organize, and share structured content. It combines the feel of a native notes app with the power of a rich text editor (Tiptap/ProseMirror) and a community content library.

## Platforms

- **macOS** - Swift + SwiftUI (in development)
- **iOS** - Swift + SwiftUI (planned)
- **Android** - Kotlin + Jetpack Compose (planned)
- **Windows** - WinUI (planned)

## Architecture

### Native-First UX
All navigation, toolbars, menus, and UI chrome are implemented natively per platform. The rich text editor (Tiptap) runs inside a WebView, treated as an isolated editing surface.

### Content Model
- **Canonical Format**: ProseMirror JSON
- **Local Storage**: SQLite (SwiftData on Apple platforms)
- **Sync**: Offline-first with cloud sync

### Backend Stack
- **Auth**: Clerk
- **API**: Cloudflare Workers
- **Database**: Cloudflare D1 (SQLite)
- **Storage**: Cloudflare R2
- **Collaboration**: PartyKit (Yjs)
- **Export**: Cloudflare Queues → Google Docs, Confluence, PDF

## Project Structure

```
Writa/
├── Apple App/           # macOS/iOS native apps
│   └── Writa/
│       └── Writa/
│           ├── Models/      # SwiftData models
│           ├── Theme/       # Design system
│           └── Views/       # SwiftUI views
├── workers/             # Cloudflare Workers API (planned)
├── partykit/            # Real-time collaboration (planned)
└── editor/              # Tiptap editor bundle (planned)
```

## Getting Started

### macOS App

1. Open `Apple App/Writa/Writa.xcodeproj` in Xcode
2. Select the Writa scheme
3. Build and run (⌘R)

**Requirements:**
- Xcode 15+
- macOS 14.0+ deployment target

## Features

### Current (macOS Shell)
- [x] Three-column navigation (Sidebar + List + Detail)
- [x] Document organization (Folders, Tags, Smart Filters)
- [x] Theme system with design tokens
- [x] Settings with appearance customization
- [x] Community window (separate window)
- [x] Native menus and keyboard shortcuts

### Planned
- [ ] Tiptap editor integration (WebView)
- [ ] Native ↔ Editor bridge
- [ ] Offline sync
- [ ] Real-time collaboration (Yjs)
- [ ] Export pipeline
- [ ] Community content library
- [ ] Prompt snippets

## License

Proprietary - All rights reserved
