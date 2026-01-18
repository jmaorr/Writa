#!/bin/bash

# Download TipTap UMD bundles for offline use
# Run this script from the Editor folder

VENDOR_DIR="vendor"
VERSION="2.1.13"

mkdir -p "$VENDOR_DIR"

echo "Downloading TipTap $VERSION UMD bundles..."

# Core packages
curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/core@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/core.umd.js"
echo "✓ core"

# Note: @tiptap/pm is bundled with core, no separate UMD file exists

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/starter-kit@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/starter-kit.umd.js"
echo "✓ starter-kit"

# Extensions
curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-placeholder@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/placeholder.umd.js"
echo "✓ placeholder"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-underline@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/underline.umd.js"
echo "✓ underline"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-link@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/link.umd.js"
echo "✓ link"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-task-list@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/task-list.umd.js"
echo "✓ task-list"

curl -sL "https://cdn.jsdelivr.net/npm/@tiptap/extension-task-item@$VERSION/dist/index.umd.js" -o "$VENDOR_DIR/task-item.umd.js"
echo "✓ task-item"

echo ""
echo "Done! Vendor files downloaded to $VENDOR_DIR/"
echo ""
echo "Next steps:"
echo "1. In Xcode, right-click the Editor folder"
echo "2. Select 'Add Files to Writa...'"
echo "3. Select the 'vendor' folder"
echo "4. Make sure 'Copy items if needed' is UNCHECKED"
echo "5. Make sure 'Create folder references' is SELECTED (blue folder)"
echo "6. Make sure your app target is checked"
echo ""
