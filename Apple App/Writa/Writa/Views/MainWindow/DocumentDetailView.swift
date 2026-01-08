//
//  DocumentDetailView.swift
//  Writa
//
//  Document content view - shows document in read mode or editor.
//  This will eventually host the WebView with Tiptap editor.
//

import SwiftUI

struct DocumentDetailView: View {
    @Bindable var document: Document
    @Environment(\.themeManager) private var themeManager
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isEditing {
                EditorPlaceholderView(document: document)
            } else {
                ReadModeView(document: document)
            }
        }
        .navigationTitle(document.displayTitle)
        .navigationSubtitle(document.formattedDate)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                editToggle
                shareMenu
                moreMenu
            }
        }
        .background(themeManager.tokens.colors.editorBackground)
    }
    
    // MARK: - Edit Toggle
    
    private var editToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing.toggle()
            }
        } label: {
            Label(
                isEditing ? "Done" : "Edit",
                systemImage: isEditing ? "checkmark" : "pencil"
            )
        }
        .keyboardShortcut("e", modifiers: .command)
    }
    
    // MARK: - Share Menu
    
    private var shareMenu: some View {
        Menu {
            Button {
                // Export to Google Docs
            } label: {
                Label("Export to Google Docs", systemImage: "doc.text")
            }
            
            Button {
                // Export to Confluence
            } label: {
                Label("Export to Confluence", systemImage: "link")
            }
            
            Divider()
            
            Button {
                // Export as PDF
            } label: {
                Label("Export as PDF", systemImage: "doc.richtext")
            }
            
            Button {
                // Export as DOCX
            } label: {
                Label("Export as Word", systemImage: "doc.text.fill")
            }
            
            Divider()
            
            Button {
                // Copy link
            } label: {
                Label("Copy Link", systemImage: "link")
            }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
    
    // MARK: - More Menu
    
    private var moreMenu: some View {
        Menu {
            Button {
                document.isFavorite.toggle()
            } label: {
                Label(
                    document.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: document.isFavorite ? "star.fill" : "star"
                )
            }
            
            Button {
                document.isPinned.toggle()
            } label: {
                Label(
                    document.isPinned ? "Unpin" : "Pin to Top",
                    systemImage: document.isPinned ? "pin.slash" : "pin"
                )
            }
            
            Divider()
            
            Button {
                // Show document info
            } label: {
                Label("Document Info", systemImage: "info.circle")
            }
            
            Button {
                // Show version history
            } label: {
                Label("Version History", systemImage: "clock.arrow.circlepath")
            }
            
            Divider()
            
            Button(role: .destructive) {
                // Move to trash
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
}

// MARK: - Read Mode View

struct ReadModeView: View {
    let document: Document
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(document.displayTitle)
                    .font(themeManager.tokens.typography.title1.font)
                    .foregroundStyle(themeManager.tokens.colors.textPrimary)
                
                // Summary if available
                if !document.summary.isEmpty {
                    Text(document.summary)
                        .font(themeManager.tokens.typography.subheadline.font)
                        .foregroundStyle(themeManager.tokens.colors.textSecondary)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Content placeholder
                if document.plainText.isEmpty {
                    ContentUnavailableView {
                        Label("No Content", systemImage: "doc.text")
                    } description: {
                        Text("Click Edit to start writing.")
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    Text(document.plainText)
                        .font(themeManager.tokens.typography.body.font)
                        .foregroundStyle(themeManager.tokens.colors.textPrimary)
                        .lineSpacing(themeManager.tokens.typography.body.lineHeight * 4)
                }
                
                Spacer(minLength: 100)
            }
            .padding(32)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Editor Placeholder View

struct EditorPlaceholderView: View {
    let document: Document
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Editor toolbar placeholder
            EditorToolbarPlaceholder()
            
            Divider()
            
            // WebView placeholder
            ZStack {
                themeManager.tokens.colors.editorBackground
                
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    
                    Text("Tiptap Editor")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("WebView will be embedded here with the Tiptap rich text editor.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Editor Toolbar Placeholder

struct EditorToolbarPlaceholder: View {
    var body: some View {
        HStack(spacing: 2) {
            Group {
                // Text formatting
                toolbarButton(icon: "bold", tooltip: "Bold")
                toolbarButton(icon: "italic", tooltip: "Italic")
                toolbarButton(icon: "underline", tooltip: "Underline")
                toolbarButton(icon: "strikethrough", tooltip: "Strikethrough")
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                // Headings
                toolbarButton(icon: "textformat.size", tooltip: "Heading")
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                // Lists
                toolbarButton(icon: "list.bullet", tooltip: "Bullet List")
                toolbarButton(icon: "list.number", tooltip: "Numbered List")
                toolbarButton(icon: "checklist", tooltip: "Checklist")
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                // Blocks
                toolbarButton(icon: "text.quote", tooltip: "Quote")
                toolbarButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code")
                toolbarButton(icon: "exclamationmark.triangle", tooltip: "Callout")
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                // Media
                toolbarButton(icon: "photo", tooltip: "Image")
                toolbarButton(icon: "link", tooltip: "Link")
            }
            
            Spacer()
            
            // Word count
            Text("0 words")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func toolbarButton(icon: String, tooltip: String) -> some View {
        Button {
            // Placeholder action
        } label: {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .help(tooltip)
    }
}

// MARK: - Preview

#Preview {
    let document = Document(
        title: "Sample Document",
        summary: "A brief summary of the document content.",
        plainText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    )
    
    return NavigationStack {
        DocumentDetailView(document: document)
    }
    .frame(width: 800, height: 600)
}
