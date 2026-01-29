//
//  DocumentDetailView.swift
//  Writa
//
//  Document content view - shows document in read mode or editor.
//  Uses native SwiftUI editor with Liquid Glass toolbar.
//

import SwiftUI
import WebKit

struct DocumentDetailView: View {
    @Bindable var document: Document
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.autosaveManager) private var autosaveManager
    
    @State private var webView: WKWebView?
    @State private var editorState = EditorState()
    @State private var wordCount: Int = 0
    @State private var isEditorReady = false
    @State private var currentDocumentId: UUID?
    @State private var keyboardMonitor: Any?
    
    // MARK: - Editor View Selection
    
    @ViewBuilder
    private var editorView: some View {
        TiptapCollabEditorView(
            document: document,
            webView: $webView,
            editorState: $editorState,
            wordCount: $wordCount,
            themeCSS: themeManager.editorCSS(for: colorScheme),
            onShowImagePicker: showImagePicker,
            onShowLinkDialog: showLinkDialog,
            onShowColorPicker: showColorPicker,
            isEditorReady: $isEditorReady
        )
    }
    
    var body: some View {
        editorView
        .navigationTitle(document.displayTitle)
        .navigationSubtitle(document.formattedDate)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                shareMenu
            }
            ToolbarItemGroup(placement: .primaryAction) {
                moreMenu
            }
        }
        .background(themeManager.tokens.colors.editorBackground)
        .onAppear {
            setupKeyboardShortcuts()
            currentDocumentId = document.id
        }
        .onDisappear {
            // Clean up keyboard monitor when view disappears
            removeKeyboardMonitor()
        }
        .onChange(of: document.id) { oldValue, newValue in
            // Document changed - swap content in existing WebView (no skeleton needed)
            handleDocumentChange(from: oldValue, to: newValue)
            
            // Re-setup keyboard shortcuts for the new document
            setupKeyboardShortcuts()
        }
        .onChange(of: colorScheme) { _, _ in
            // Re-apply theme when color scheme changes
            applyThemeCSS()
        }
        .onChange(of: themeManager.editorSettingsVersion) { _, _ in
            // Re-apply theme when any editor setting changes
            applyThemeCSS()
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskToggled)) { notification in
            handleTaskToggled(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("InsertPromptSnippet"))) { _ in
            webView?.insertPromptSnippet()
        }
    }
    
    // MARK: - Task Sync
    
    private func handleTaskToggled(_ notification: Notification) {
        guard let toggleInfo = notification.object as? TaskToggleInfo,
              toggleInfo.documentID == document.id,
              let webView = webView else { return }
        
        // Send command to TipTap to sync the task state
        let js = "editorBridge.setTaskChecked(\(toggleInfo.nodeIndex), \(toggleInfo.isCompleted))"
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("❌ Error syncing task toggle: \(error)")
            } else {
                print("✅ Synced task toggle to editor")
            }
        }
    }
    
    // MARK: - Theme Application
    
    private func applyThemeCSS() {
        guard let webView = webView, isEditorReady else { return }
        let css = themeManager.editorCSS(for: colorScheme)
        let escapedCSS = css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        webView.evaluateJavaScript("editorBridge.setThemeCSS('\(escapedCSS)')") { _, error in
            if let error = error {
                print("⚠️ Error applying theme CSS: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Document Change Handling
    
    private func handleDocumentChange(from oldId: UUID, to newId: UUID) {
        guard oldId != newId else { return }
        
        // Update tracking for autosave manager (lastOpenedAt)
        autosaveManager.stopEditing()
        
        // Reset editor state for new document
        editorState = EditorState()
        wordCount = document.wordCount
        currentDocumentId = newId
        
        // Start tracking new document
        autosaveManager.startEditing(document)
        
        // Content loading is handled by TiptapCollabWebView via Yjs
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
            Image(systemName: "square.and.arrow.up")
        }
        .menuIndicator(.hidden)
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
            Image(systemName: "ellipsis")
        }
        .menuIndicator(.hidden)
    }
    
    // MARK: - Helper Methods
    
    private func showImagePicker() {
        // TODO: Implement image picker
        print("Show image picker")
    }
    
    private func showLinkDialog() {
        // TODO: Implement link dialog
        print("Show link dialog")
    }
    
    private func showColorPicker() {
        // TODO: Implement color picker
        print("Show color picker")
    }
    
    // MARK: - Keyboard Shortcuts
    
    private func removeKeyboardMonitor() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Remove any existing monitor first to prevent duplicate handlers
        removeKeyboardMonitor()
        
        // Capture current document ID to verify shortcuts fire for correct document
        let targetDocumentId = document.id
        
        // Register keyboard shortcuts via NSEvent monitor
        // These will forward to the TipTap editor
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            // Only process if this is still the current document
            guard currentDocumentId == targetDocumentId,
                  let webView = webView else { return event }
            
            let flags = event.modifierFlags
            let isCmd = flags.contains(.command)
            let isShift = flags.contains(.shift)
            let isOpt = flags.contains(.option)
            
            // Only handle command key combinations
            guard isCmd else { return event }
            
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
            
            switch (key, isShift, isOpt) {
            // Text Styles (simple Cmd+Number)
            case ("1", false, false): webView.toggleHeading1(); return nil
            case ("2", false, false): webView.toggleHeading2(); return nil
            case ("0", false, false): webView.setHeading(level: 0); return nil
            
            // Text formatting
            case ("b", false, false): webView.toggleBold(); return nil
            case ("i", false, false): webView.toggleItalic(); return nil
            case ("u", false, false): webView.toggleUnderline(); return nil
            case ("e", false, false): webView.toggleCode(); return nil
            case ("k", false, false): showLinkDialog(); return nil
            case ("x", true, false): webView.toggleStrike(); return nil
            case ("h", true, false):
                webView.evaluateJavaScript("editorBridge.toggleHighlight()")
                // Notify toolbar to toggle color picker
                NotificationCenter.default.post(name: NSNotification.Name("ToggleHighlightColors"), object: nil)
                return nil
            
            // Lists
            case ("7", true, false): webView.toggleOrderedList(); return nil
            case ("8", true, false): webView.toggleBulletList(); return nil
            case ("9", true, false): webView.toggleTaskList(); return nil
            
            // Task Cards
            case ("t", true, false): webView.insertTaskCard(); return nil
            
            // Prompt Snippets (⌘⇧P - handled by menu command, kept here as fallback)
            case ("p", true, false): 
                webView.insertPromptSnippet()
                return nil
            
            // Blocks
            case ("b", true, false): webView.toggleBlockquote(); return nil
            case ("c", false, true): webView.toggleCodeBlock(); return nil
            
            // Alignment
            case ("l", true, false): webView.evaluateJavaScript("editorBridge.setTextAlign('left')"); return nil
            case ("e", true, false): webView.evaluateJavaScript("editorBridge.setTextAlign('center')"); return nil
            case ("r", true, false): webView.evaluateJavaScript("editorBridge.setTextAlign('right')"); return nil
            case ("j", true, false): webView.evaluateJavaScript("editorBridge.setTextAlign('justify')"); return nil
            
            // Media
            case ("i", true, false): showImagePicker(); return nil
            
            default:
                return event
            }
        }
    }
}

// MARK: - Read Mode View

struct ReadModeView: View {
    let document: Document
    let onTap: () -> Void
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
                        Text("Click anywhere to start writing.")
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
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Editor Skeleton View (Loading State)

struct EditorSkeletonView: View {
    let document: Document
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Show actual content preview if available
                if !document.plainText.isEmpty {
                    Text(document.plainText)
                        .font(.system(size: themeManager.editorFontSize, weight: .regular))
                        .foregroundStyle(themeManager.tokens.colors.textPrimary)
                        .lineSpacing(themeManager.editorLineHeight * themeManager.editorFontSize - themeManager.editorFontSize)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0.6) // Slightly faded to indicate loading state
                } else {
                    // Placeholder for empty documents
                    Text("Start writing...")
                        .font(.system(size: themeManager.editorFontSize))
                        .foregroundStyle(.tertiary)
                }
                
                Spacer(minLength: 100)
            }
            .padding(themeManager.editorPadding)
            .padding(.top, 52) // Extra space for formatting toolbar
            .frame(maxWidth: themeManager.editorContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(colorScheme == .dark ? themeManager.editorBackgroundColorDark : themeManager.editorBackgroundColorLight)
        .overlay(alignment: .top) {
            // Subtle loading shimmer overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.03),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 200, height: 2)
                .offset(x: isAnimating ? 400 : -400, y: 4)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

// MARK: - Collaborative TipTap Editor View (Yjs/PartyKit)

struct TiptapCollabEditorView: View {
    @Bindable var document: Document
    @Binding var webView: WKWebView?
    @Binding var editorState: EditorState
    @Binding var wordCount: Int
    var themeCSS: String
    var onShowImagePicker: () -> Void
    var onShowLinkDialog: () -> Void
    var onShowColorPicker: () -> Void
    @Binding var isEditorReady: Bool
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main editor content
            ZStack {
                // Skeleton shown while loading
                if !isEditorReady {
                    EditorSkeletonView(document: document)
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                        .zIndex(1)
                }
                
                // Collaborative WebView
                TiptapCollabWebView(
                    documentId: document.id,
                    userId: nil,  // TODO: Get from auth
                    userName: nil,  // TODO: Get from auth
                    userColor: nil,
                    themeCSS: themeCSS,
                    onReady: {
                        print("📝 TipTap collaborative editor ready!")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isEditorReady = true
                            }
                        }
                    },
                    onContentChange: { plainText, title, jsonContent in
                        // Update word count for display
                        wordCount = plainText.isEmpty ? 0 : plainText.split(separator: " ").count
                        
                        // Update document title if extracted from content
                        if !title.isEmpty && document.title != title {
                            document.title = title
                        }
                        
                        // Update plain text for search/preview
                        if document.plainText != plainText {
                            document.plainText = plainText
                        }
                        
                        // Update JSON content for task extraction
                        if let jsonContent = jsonContent {
                            document.content = jsonContent
                        }
                        
                        // Update timestamp for sorting by modified date
                        document.updatedAt = Date()
                    },
                    onMetaChange: { meta in
                        // Sync metadata from Yjs to SwiftData (for local queries)
                        // This allows the document list to show updated metadata
                        DispatchQueue.main.async {
                            // IMPORTANT: Never restore a locally-trashed document from Yjs
                            // This prevents the "bouncing back from trash" bug
                            if document.isTrashed && !meta.isDeleted {
                                print("⚠️ Ignoring Yjs restore for locally-trashed document: \(document.displayTitle)")
                                return
                            }
                            
                            if document.isTrashed != meta.isDeleted {
                                document.isTrashed = meta.isDeleted  // Yjs uses isDeleted, local uses isTrashed
                                document.trashedAt = meta.deletedAt
                            }
                            if !meta.title.isEmpty && document.title != meta.title {
                                document.title = meta.title
                            }
                            document.isFavorite = meta.isFavorite
                            document.isPinned = meta.isPinned
                            document.tags = meta.tags
                            // Note: We don't set isDirty because Yjs handles sync
                        }
                    },
                    onConnectionChange: { _ in
                        // Connection status is transparent - no UI needed
                    },
                    onSelectionChange: { state in
                        editorState = state
                    },
                    webViewRef: $webView
                )
                .opacity(isEditorReady ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isEditorReady)
                .zIndex(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Formatting toolbar
            VStack(spacing: 0) {
                LiquidGlassEditorToolbar(
                    webView: $webView,
                    editorState: editorState,
                    wordCount: wordCount,
                    onShowImagePicker: onShowImagePicker,
                    onShowLinkDialog: onShowLinkDialog,
                    onShowColorPicker: onShowColorPicker
                )
                Spacer()
            }
            
        }
    }
}

// MARK: - Liquid Glass Editor Toolbar

struct LiquidGlassEditorToolbar: View {
    @Binding var webView: WKWebView?
    var editorState: EditorState
    var wordCount: Int
    var onShowImagePicker: () -> Void
    var onShowLinkDialog: () -> Void
    var onShowColorPicker: () -> Void
    
    @Environment(\.toolbarConfiguration) private var config
    
    // State for cascade animation
    @State private var showColorPicker: Bool = false
    @State private var visibleColorCount: Int = 0
    
    // Spacing values
    private let glassSpacing: CGFloat = 16.0
    private let mergeOffset: CGFloat = -10.0
    private let buttonSize: CGFloat = 32.0
    private let iconSize: CGFloat = 14.0
    private let textButtonPadding: CGFloat = 12.0
    
    // Whether the color picker section should affect layout (based on visible colors, not showColorPicker flag)
    private var colorPickerVisible: Bool {
        visibleColorCount > 0
    }
    
    var body: some View {
        GlassEffectContainer(spacing: glassSpacing) {
            HStack(spacing: glassSpacing) {
                // Find which group contains the highlight tool
                let highlightGroupIndex = config.groups.firstIndex(where: { $0.contains(.highlight) })
                
                // Render groups from configuration
                ForEach(Array(config.groups.enumerated()), id: \.offset) { index, tools in
                    if !tools.isEmpty {
                        // Calculate offset: groups after highlight get extra offset when highlight colors are shown
                        let groupOffset: CGFloat = {
                            if index == 0 { return 0 }
                            var offset = CGFloat(index)
                            // If colors are visible and this group comes after the highlight group, add extra offset
                            if colorPickerVisible, let highlightIndex = highlightGroupIndex, index > highlightIndex {
                                offset += 1 // Extra offset to merge with color picker
                            }
                            return mergeOffset * offset
                        }()
                        
                        toolGroup(tools)
                            .glassEffect(.regular, in: .capsule)
                            .offset(x: groupOffset)
                        
                        // Insert highlight color picker right after the group containing highlight
                        if showColorPicker && index == highlightGroupIndex {
                            highlightColorPicker
                                .glassEffect(.regular, in: .capsule)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                                .offset(x: mergeOffset * CGFloat(index + 1))
                                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: visibleColorCount)
                        }
                    }
                }
                
                // Overflow menu for hidden tools
                if !config.hiddenTools.isEmpty {
                    let overflowOffset = config.groups.count + (colorPickerVisible && highlightGroupIndex != nil ? 1 : 0)
                    overflowButton
                        .glassEffect(.regular, in: .capsule)
                        .offset(x: mergeOffset * CGFloat(overflowOffset))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: colorPickerVisible)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: config.groups.count)
            .onChange(of: editorState.isHighlight) { oldValue, newValue in
                // Only respond to editor state changes if picker state doesn't already match
                // This handles cursor movement into/out of highlighted text
                if newValue && !showColorPicker {
                    // Cursor moved into highlighted text - show color picker
                    showColorPicker = true
                    visibleColorCount = 0
                    for i in 0..<6 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                            if showColorPicker {
                                visibleColorCount = i + 1
                            }
                        }
                    }
                } else if !newValue && showColorPicker {
                    // Cursor moved out of highlighted text - hide color picker
                    for i in (0..<6).reversed() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(6 - i - 1) * 0.02) {
                            visibleColorCount = i
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(6) * 0.02 + 0.15) {
                        showColorPicker = false
                        visibleColorCount = 0
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleHighlightColors"))) { _ in
                // Keyboard shortcut triggered - toggle color picker
                toggleColorPicker()
            }
        }
    }
    
    // MARK: - Toggle Color Picker
    
    private func toggleColorPicker() {
        if showColorPicker {
            // Close: cascade colors out
            for i in (0..<6).reversed() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(6 - i - 1) * 0.02) {
                    visibleColorCount = i
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(6) * 0.02 + 0.15) {
                showColorPicker = false
                visibleColorCount = 0
            }
        } else {
            // Open: cascade colors in
            showColorPicker = true
            visibleColorCount = 0
            for i in 0..<6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                    if showColorPicker {
                        visibleColorCount = i + 1
                    }
                }
            }
        }
    }
    
    // MARK: - Tool Group
    
    @ViewBuilder
    private func toolGroup(_ tools: [EditorTool]) -> some View {
        HStack(spacing: 0) {
            ForEach(tools) { tool in
                toolButton(for: tool)
            }
        }
    }
    
    // MARK: - Tool Button
    
    @ViewBuilder
    private func toolButton(for tool: EditorTool) -> some View {
        let isActive = isToolActive(tool)
        let tooltip = tool.shortcut.map { "\(tool.displayName) (\($0))" } ?? tool.displayName
        
        Button {
            executeToolAction(tool)
        } label: {
            if let label = tool.toolbarLabel {
                // Text label button (Title, Heading, Body)
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? Color.accentColor : .primary)
                    .padding(.horizontal, textButtonPadding)
                    .frame(height: buttonSize)
            } else {
                // Icon button
                Image(systemName: tool.icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundStyle(isActive ? Color.accentColor : .primary)
            }
        }
        .buttonStyle(.borderless)
        .help(tooltip)
    }
    
    // MARK: - Overflow Button
    
    private var overflowButton: some View {
        HStack(spacing: 0) {
            Menu {
                ForEach(ToolCategory.allCases) { category in
                    let categoryTools = category.tools.filter { config.hiddenTools.contains($0) }
                    
                    if !categoryTools.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categoryTools) { tool in
                                Button {
                                    executeToolAction(tool)
                                } label: {
                                    Label(tool.displayName, systemImage: tool.icon)
                                }
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .menuIndicator(.hidden)
            .buttonStyle(.borderless)
            .help("More formatting options")
        }
        .frame(width: buttonSize, height: buttonSize)
    }
    
    // MARK: - Highlight Color Picker
    
    private var highlightColorPicker: some View {
        // Common highlight colors
        let colors: [(name: String, color: Color)] = [
            ("Yellow", Color(hex: "#fef08a") ?? .yellow),
            ("Green", Color(hex: "#86efac") ?? .green),
            ("Blue", Color(hex: "#93c5fd") ?? .blue),
            ("Pink", Color(hex: "#f9a8d4") ?? .pink),
            ("Orange", Color(hex: "#fdba74") ?? .orange),
            ("Purple", Color(hex: "#c4b5fd") ?? .purple)
        ]
        
        // Calculate width based on visible colors (20px per color + 4px spacing + 16px padding)
        let colorWidth: CGFloat = 20.0
        let spacing: CGFloat = 4.0
        let horizontalPadding: CGFloat = 16.0
        let calculatedWidth = CGFloat(visibleColorCount) * colorWidth + CGFloat(max(0, visibleColorCount - 1)) * spacing + horizontalPadding
        
        return HStack(spacing: 4) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, colorInfo in
                let isSelected = editorState.highlightColor?.lowercased() == colorInfo.color.toHex()?.lowercased()
                let isVisible = visibleColorCount > index
                
                Button {
                    if let hex = colorInfo.color.toHex() {
                        webView?.evaluateJavaScript("editorBridge.setHighlightColor('\(hex)')")
                    }
                } label: {
                    Circle()
                        .fill(colorInfo.color)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(colorInfo.name)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.3)
                .offset(x: isVisible ? 0 : -30)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isVisible)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: calculatedWidth, alignment: .leading)
        .clipped() // Clip to prevent overflow during animation
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: visibleColorCount)
    }
    
    // MARK: - Tool State
    
    private func isToolActive(_ tool: EditorTool) -> Bool {
        switch tool {
        case .title: return editorState.headingLevel == 1
        case .heading: return editorState.headingLevel == 2
        case .body: return editorState.headingLevel == 0
        case .bold: return editorState.isBold
        case .italic: return editorState.isItalic
        case .underline: return editorState.isUnderline
        case .strikethrough: return editorState.isStrike
        case .code: return editorState.isCode
        case .highlight: return editorState.isHighlight
        case .subscript_: return editorState.isSubscript
        case .superscript_: return editorState.isSuperscript
        case .alignLeft: return editorState.textAlign == "left"
        case .alignCenter: return editorState.textAlign == "center"
        case .alignRight: return editorState.textAlign == "right"
        case .alignJustify: return editorState.textAlign == "justify"
        case .bulletList: return editorState.isBulletList
        case .numberedList: return editorState.isOrderedList
        case .taskList: return editorState.isTaskList
        case .taskCard: return editorState.isTaskCard
        case .quote: return editorState.isBlockquote
        case .codeBlock: return editorState.isCodeBlock
        case .link: return editorState.isLink
        default: return false
        }
    }
    
    // MARK: - Tool Actions
    
    private func executeToolAction(_ tool: EditorTool) {
        guard let webView = webView else { return }
        
        switch tool {
        case .title:
            webView.toggleHeading1()
        case .heading:
            webView.toggleHeading2()
        case .body:
            webView.setHeading(level: 0)
        case .bold:
            webView.toggleBold()
        case .italic:
            webView.toggleItalic()
        case .underline:
            webView.toggleUnderline()
        case .strikethrough:
            webView.toggleStrike()
        case .code:
            webView.toggleCode()
        case .highlight:
            // Toggle highlight in the editor
            webView.evaluateJavaScript("editorBridge.toggleHighlight()")
            // Toggle color picker with cascade animation
            toggleColorPicker()
        case .subscript_:
            webView.evaluateJavaScript("editorBridge.toggleSubscript()")
        case .superscript_:
            webView.evaluateJavaScript("editorBridge.toggleSuperscript()")
        case .alignLeft:
            webView.evaluateJavaScript("editorBridge.setTextAlign('left')")
        case .alignCenter:
            webView.evaluateJavaScript("editorBridge.setTextAlign('center')")
        case .alignRight:
            webView.evaluateJavaScript("editorBridge.setTextAlign('right')")
        case .alignJustify:
            webView.evaluateJavaScript("editorBridge.setTextAlign('justify')")
        case .bulletList:
            webView.toggleBulletList()
        case .numberedList:
            webView.toggleOrderedList()
        case .taskList:
            webView.toggleTaskList()
        case .taskCard:
            webView.insertTaskCard()
        case .quote:
            webView.toggleBlockquote()
        case .codeBlock:
            webView.toggleCodeBlock()
        case .divider:
            webView.evaluateJavaScript("editorBridge.setHorizontalRule()")
        case .image:
            onShowImagePicker()
        case .link:
            onShowLinkDialog()
        case .table:
            webView.evaluateJavaScript("editorBridge.insertTable()")
        case .promptSnippet:
            webView.insertPromptSnippet()
        case .textColor:
            onShowColorPicker()
        }
    }
    
}

// MARK: - Native Editor View (Alternative)

struct NativeEditorView: View {
    @Bindable var document: Document
    @Binding var editorState: EditorState
    @Binding var wordCount: Int
    
    @Environment(\.themeManager) private var themeManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Liquid Glass toolbar
            NativeEditorToolbar(
                document: document,
                editorState: $editorState,
                wordCount: wordCount
            )
            
            Divider()
            
            // Native TextEditor
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Title field
                    TextField("Untitled", text: $document.title)
                        .font(.system(size: 32, weight: .bold))
                        .textFieldStyle(.plain)
                        .foregroundStyle(themeManager.tokens.colors.textPrimary)
                    
                    Spacer().frame(height: 24)
                    
                    // Main content editor
                    TextEditor(text: $document.plainText)
                        .font(themeManager.tokens.typography.body.font)
                        .foregroundStyle(themeManager.tokens.colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                        .frame(minHeight: 400)
                }
                .padding(32)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(themeManager.tokens.colors.editorBackground)
        }
        .onAppear {
            updateWordCount()
            isFocused = true
        }
        .onChange(of: document.plainText) { _, _ in
            updateWordCount()
            // Note: updatedAt is managed by AutosaveManager on actual content changes
            // Don't update here to avoid timestamp changes on load/sync
        }
    }
    
    private func updateWordCount() {
        let text = document.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        wordCount = text.isEmpty ? 0 : text.split(whereSeparator: { $0.isWhitespace }).count
        document.wordCount = wordCount
    }
}

// MARK: - Native Editor Toolbar

struct NativeEditorToolbar: View {
    @Bindable var document: Document
    @Binding var editorState: EditorState
    var wordCount: Int
    
    @Environment(\.toolbarConfiguration) private var config
    
    // Spacing values
    private let glassSpacing: CGFloat = 16.0
    private let mergeOffset: CGFloat = -10.0
    private let buttonSize: CGFloat = 32.0
    private let iconSize: CGFloat = 14.0
    
    var body: some View {
        GlassEffectContainer(spacing: glassSpacing) {
            HStack(spacing: glassSpacing) {
                // Render groups from configuration
                ForEach(Array(config.groups.enumerated()), id: \.offset) { index, tools in
                    if !tools.isEmpty {
                        toolGroup(tools)
                            .glassEffect(.regular, in: .capsule)
                            .offset(x: index > 0 ? mergeOffset * CGFloat(index) : 0)
                    }
                }
                
                // Overflow menu for hidden tools
                if !config.hiddenTools.isEmpty {
                    overflowButton
                        .glassEffect(.regular, in: .capsule)
                        .offset(x: mergeOffset * CGFloat(config.groups.count))
                }
                
                Spacer()
                
                // Word count
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Tool Group
    
    @ViewBuilder
    private func toolGroup(_ tools: [EditorTool]) -> some View {
        HStack(spacing: 0) {
            ForEach(tools) { tool in
                toolButton(for: tool)
            }
        }
    }
    
    // MARK: - Tool Button
    
    @ViewBuilder
    private func toolButton(for tool: EditorTool) -> some View {
        let isActive = isToolActive(tool)
        let tooltip = tool.shortcut.map { "\(tool.displayName) (\($0))" } ?? tool.displayName
        
        Button {
            executeToolAction(tool)
        } label: {
            if let label = tool.customLabel {
                Text(label)
                    .font(.system(size: iconSize, weight: .bold, design: .rounded))
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundStyle(isActive ? .primary : .secondary)
            } else {
                Image(systemName: tool.icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundStyle(isActive ? .primary : .secondary)
            }
        }
        .buttonStyle(.borderless)
        .help(tooltip)
    }
    
    // MARK: - Overflow Button
    
    private var overflowButton: some View {
        HStack(spacing: 0) {
            Menu {
                ForEach(ToolCategory.allCases) { category in
                    let categoryTools = category.tools.filter { config.hiddenTools.contains($0) }
                    
                    if !categoryTools.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categoryTools) { tool in
                                Button {
                                    executeToolAction(tool)
                                } label: {
                                    Label(tool.displayName, systemImage: tool.icon)
                                }
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .menuIndicator(.hidden)
            .buttonStyle(.borderless)
            .help("More formatting options")
        }
        .frame(width: buttonSize, height: buttonSize)
    }
    
    // MARK: - Tool State (placeholder - native editor doesn't track formatting state yet)
    
    private func isToolActive(_ tool: EditorTool) -> Bool {
        // For native TextEditor, we don't have formatting state tracking yet
        // This will be implemented when we add AttributedString support
        return false
    }
    
    // MARK: - Tool Actions (placeholder - will be implemented with AttributedString)
    
    private func executeToolAction(_ tool: EditorTool) {
        // TODO: Implement formatting actions with AttributedString
        // For now, tools are visual placeholders
        print("Tool action: \(tool.displayName)")
    }
}

// MARK: - Legacy TipTap Editor View (kept for future use)
// TipTap integration is currently disabled due to macOS sandbox restrictions
// with WKWebView. The native editor above provides basic functionality.
// To re-enable TipTap:
// 1. Properly configure App Sandbox entitlements
// 2. Bundle TipTap JS locally (see Editor/vendor folder)
// 3. Switch back to TiptapEditorView in DocumentDetailView body

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
