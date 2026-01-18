#!/bin/bash

# Download TipTap ES modules for local bundling
# This ensures offline support and faster loading

VERSION="2.1.13"
OUTPUT_DIR="vendor/esm"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "📦 Downloading TipTap ES modules v${VERSION}..."

# Core packages
packages=(
  # Core
  "@tiptap/core"
  "@tiptap/pm"
  
  # Essential extensions (StarterKit components)
  "@tiptap/extension-document"
  "@tiptap/extension-paragraph"
  "@tiptap/extension-text"
  "@tiptap/extension-bold"
  "@tiptap/extension-italic"
  "@tiptap/extension-strike"
  "@tiptap/extension-code"
  "@tiptap/extension-code-block"
  "@tiptap/extension-blockquote"
  "@tiptap/extension-heading"
  "@tiptap/extension-horizontal-rule"
  "@tiptap/extension-hard-break"
  "@tiptap/extension-bullet-list"
  "@tiptap/extension-ordered-list"
  "@tiptap/extension-list-item"
  "@tiptap/extension-history"
  "@tiptap/extension-dropcursor"
  "@tiptap/extension-gapcursor"
  
  # Additional essential extensions
  "@tiptap/extension-underline"
  "@tiptap/extension-link"
  "@tiptap/extension-placeholder"
  "@tiptap/extension-task-list"
  "@tiptap/extension-task-item"
  "@tiptap/extension-image"
  "@tiptap/extension-table"
  "@tiptap/extension-table-row"
  "@tiptap/extension-table-cell"
  "@tiptap/extension-table-header"
  "@tiptap/extension-highlight"
  "@tiptap/extension-text-align"
  "@tiptap/extension-subscript"
  "@tiptap/extension-superscript"
  "@tiptap/extension-color"
  "@tiptap/extension-text-style"
)

for package in "${packages[@]}"; do
  # Extract package name (remove @tiptap/ prefix)
  name=${package#@tiptap/}
  
  echo "  ⬇️  ${package}"
  
  # Download from esm.sh
  curl -s "https://esm.sh/${package}@${VERSION}" > "$OUTPUT_DIR/${name}.js"
  
  # Check if download was successful
  if [ $? -eq 0 ]; then
    echo "    ✅ ${name}.js"
  else
    echo "    ❌ Failed to download ${name}"
  fi
done

echo ""
echo "✅ Downloaded $(ls -1 $OUTPUT_DIR | wc -l | xargs) ES modules to $OUTPUT_DIR"
echo ""
echo "📝 Next steps:"
echo "   1. Update index.html to use local ES modules"
echo "   2. Ensure Xcode bundles the vendor/esm folder"
echo "   3. Test offline functionality"
