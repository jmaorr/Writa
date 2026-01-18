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
├── Apple App/Writa/Writa/
│   ├── Models/              # SwiftData models (Document, Folder)
│   ├── Services/            # Auth & Sync services (✅ Ready)
│   ├── Theme/               # Design system & tokens
│   ├── Views/
│   │   ├── MainWindow/      # Document list & editor
│   │   ├── Editor/          # TipTap WebView wrapper
│   │   ├── Settings/        # Toolbar customization
│   │   └── Community/       # Content library (planned)
│   └── Editor/              # TipTap editor (✅ Working)
│       ├── index.html       # ES modules from CDN
│       └── vendor/esm/      # 36 local ES modules
├── CLERK_CLOUDFLARE_SETUP.md    # 🎯 Start here for production
├── TECH_STACK_COMPARISON.md     # Compare backend options
├── API_INTEGRATION.md           # Alternative integrations
└── SETUP.md                     # Complete technical docs
```

## Getting Started

### Quick Start (macOS App)

1. Open `Apple App/Writa/Writa.xcodeproj` in Xcode
2. Select the Writa scheme
3. Build and run (⌘R)
4. Create a new document and start writing!

**Requirements:**
- Xcode 15+
- macOS 14.0+ deployment target

### Production Setup

To deploy with authentication and cloud sync:

1. **Setup Authentication & Backend** (Recommended)
   - Follow `CLERK_CLOUDFLARE_SETUP.md` for complete Clerk + Cloudflare setup
   - Estimated time: 2-3 hours

2. **Alternative Stacks** (If needed)
   - See `TECH_STACK_COMPARISON.md` for Firebase, Supabase, or custom API options
   - Follow `API_INTEGRATION.md` for implementation guides

3. **Editor Details**
   - See `SETUP.md` for complete technical documentation
   - Editor works offline with CDN (online required currently)
   - Local ES modules available in `Apple App/Writa/Writa/Editor/vendor/esm/`

### What's Working Right Now

✅ **Full rich-text editor** with 30+ formatting tools  
✅ **Local-first** storage with SwiftData  
✅ **Beautiful UI** with Liquid Glass toolbar  
✅ **Keyboard shortcuts** for power users  
✅ **Theme system** (light/dark mode)  
✅ **Offline mode** (no cloud required for local use)

🚧 **Cloud sync** ready but needs backend deployment  
🚧 **Authentication** infrastructure ready, needs Clerk configuration

## Features

### ✅ Completed (macOS)
- [x] Three-column navigation (Sidebar + List + Detail)
- [x] Document organization (Folders, Tags, Smart Filters)
- [x] Theme system with design tokens
- [x] Settings with appearance customization
- [x] Community window (separate window)
- [x] Native menus and keyboard shortcuts
- [x] **TipTap editor integration** (WebView with ES modules)
- [x] **Native ↔ Editor bridge** (Swift ↔ JavaScript)
- [x] **30+ editor tools** (Bold, Italic, Headings, Lists, Tables, Images, etc.)
- [x] **Liquid Glass toolbar** (Customizable, drag & drop)
- [x] **Keyboard shortcuts** (⌘B, ⌘I, ⌘K, and 15+ more)
- [x] **Auth infrastructure** (Ready for Clerk)
- [x] **Sync service** (Ready for Cloudflare)

### 🚧 In Progress
- [ ] Clerk authentication integration
- [ ] Cloudflare Workers API deployment
- [ ] Image upload to R2
- [ ] Link dialog UI
- [ ] Color picker UI

### 📋 Planned
- [ ] Real-time collaboration (PartyKit + Yjs)
- [ ] Export pipeline (Google Docs, Confluence, PDF)
- [ ] Community content library
- [ ] Prompt snippets
- [ ] iOS app
- [ ] Android app
- [ ] Windows app

## Tech Stack

### Frontend
- **Framework**: SwiftUI (macOS native)
- **Editor**: TipTap 2.1.13 + ProseMirror
- **Database**: SwiftData (SQLite)
- **Bridge**: WKWebView (Swift ↔ JavaScript)

### Backend (Ready to Deploy)
- **Auth**: Clerk (10K MAU free)
- **API**: Cloudflare Workers (100K req/day free)
- **Database**: Cloudflare D1 (SQLite at edge)
- **Storage**: Cloudflare R2 (S3-compatible)
- **Collaboration**: PartyKit + Yjs (planned)

### Why This Stack?
- ⚡️ **Performance**: Edge computing, <50ms latency worldwide
- 💰 **Cost**: $0-30/month for 1,000+ users
- 🎨 **UX**: Best-in-class auth & editor experience
- 🚀 **Scale**: 0 → 100K users without infrastructure changes

See `TECH_STACK_COMPARISON.md` for detailed analysis.

## Documentation

- 🎯 **Start Here**: `CLERK_CLOUDFLARE_SETUP.md` - Production deployment guide
- 📊 **Compare Options**: `TECH_STACK_COMPARISON.md` - Detailed stack comparison
- 🔧 **Technical Docs**: `SETUP.md` - Complete implementation details
- 🔌 **Integrations**: `API_INTEGRATION.md` - Firebase, Supabase, custom APIs

## Contributing

Currently in private development. Contributions will be accepted once we open source.

## License

Proprietary - All rights reserved
