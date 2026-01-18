#!/bin/bash

# Download ALL TipTap extensions for full offline StarterKit support
# This downloads ~400KB total - trivial for a native app

VENDOR_DIR="vendor"
VERSION="2.1.13"

mkdir -p "$VENDOR_DIR"

echo "Downloading TipTap $VERSION complete bundle for offline use..."
echo ""

# Core
echo "📦 Core packages..."
curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/core@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/core.umd.js"
echo "  ✓ core ($(du -h "$VENDOR_DIR/core.umd.js" | cut -f1))"

# StarterKit and all its dependencies
echo ""
echo "📦 StarterKit..."
curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/starter-kit@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/starter-kit.umd.js"
echo "  ✓ starter-kit ($(du -h "$VENDOR_DIR/starter-kit.umd.js" | cut -f1))"

echo ""
echo "📦 StarterKit dependencies (18 extensions)..."
curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-blockquote@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/blockquote.umd.js"
echo "  ✓ blockquote ($(du -h "$VENDOR_DIR/blockquote.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-bold@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/bold.umd.js"
echo "  ✓ bold ($(du -h "$VENDOR_DIR/bold.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-bullet-list@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/bullet-list.umd.js"
echo "  ✓ bullet-list ($(du -h "$VENDOR_DIR/bullet-list.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-code@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/code.umd.js"
echo "  ✓ code ($(du -h "$VENDOR_DIR/code.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-code-block@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/code-block.umd.js"
echo "  ✓ code-block ($(du -h "$VENDOR_DIR/code-block.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-document@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/document.umd.js"
echo "  ✓ document ($(du -h "$VENDOR_DIR/document.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-dropcursor@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/dropcursor.umd.js"
echo "  ✓ dropcursor ($(du -h "$VENDOR_DIR/dropcursor.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-gapcursor@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/gapcursor.umd.js"
echo "  ✓ gapcursor ($(du -h "$VENDOR_DIR/gapcursor.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-hard-break@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/hard-break.umd.js"
echo "  ✓ hard-break ($(du -h "$VENDOR_DIR/hard-break.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-heading@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/heading.umd.js"
echo "  ✓ heading ($(du -h "$VENDOR_DIR/heading.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-history@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/history.umd.js"
echo "  ✓ history ($(du -h "$VENDOR_DIR/history.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-horizontal-rule@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/horizontal-rule.umd.js"
echo "  ✓ horizontal-rule ($(du -h "$VENDOR_DIR/horizontal-rule.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-italic@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/italic.umd.js"
echo "  ✓ italic ($(du -h "$VENDOR_DIR/italic.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-list-item@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/list-item.umd.js"
echo "  ✓ list-item ($(du -h "$VENDOR_DIR/list-item.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-ordered-list@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/ordered-list.umd.js"
echo "  ✓ ordered-list ($(du -h "$VENDOR_DIR/ordered-list.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-paragraph@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/paragraph.umd.js"
echo "  ✓ paragraph ($(du -h "$VENDOR_DIR/paragraph.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-strike@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/strike.umd.js"
echo "  ✓ strike ($(du -h "$VENDOR_DIR/strike.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-text@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/text.umd.js"
echo "  ✓ text ($(du -h "$VENDOR_DIR/text.umd.js" | cut -f1))"

# Additional useful extensions (not in StarterKit but we're using)
echo ""
echo "📦 Additional extensions..."
curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-placeholder@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/placeholder.umd.js"
echo "  ✓ placeholder ($(du -h "$VENDOR_DIR/placeholder.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-underline@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/underline.umd.js"
echo "  ✓ underline ($(du -h "$VENDOR_DIR/underline.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-link@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/link.umd.js"
echo "  ✓ link ($(du -h "$VENDOR_DIR/link.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-task-list@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/task-list.umd.js"
echo "  ✓ task-list ($(du -h "$VENDOR_DIR/task-list.umd.js" | cut -f1))"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-task-item@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/task-item.umd.js"
echo "  ✓ task-item ($(du -h "$VENDOR_DIR/task-item.umd.js" | cut -f1))"

echo ""
echo "✅ Done! Downloaded $(ls -1 "$VENDOR_DIR" | wc -l | tr -d ' ') files"
echo "📊 Total size: $(du -sh "$VENDOR_DIR" | cut -f1)"
echo ""
echo "Now in Xcode:"
echo "1. Make sure the vendor folder is added as a folder reference (blue folder)"
echo "2. Clean build (Cmd+Shift+K)"
echo "3. Build and run"
echo ""
