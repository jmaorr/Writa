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
    
    var body: some View {
        TiptapEditorView(
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
        .onChange(of: document.id) { oldValue, newValue in
            // Document changed - swap content in existing WebView
            handleDocumentChange(from: oldValue, to: newValue)
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
        guard let webView = webView else { return }
        let css = themeManager.editorCSS(for: colorScheme)
        let escapedCSS = css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        webView.evaluateJavaScript("editorBridge.setThemeCSS('\(escapedCSS)')")
    }
    
    // MARK: - Document Change Handling
    
    private func handleDocumentChange(from oldId: UUID, to newId: UUID) {
        guard oldId != newId else { return }
        
        // Save current document immediately
        autosaveManager.stopEditing()
        
        // Reset editor state for new document
        editorState = EditorState()
        wordCount = document.wordCount
        currentDocumentId = newId
        
        // Start editing new document
        autosaveManager.startEditing(document)
        
        // Load new content into existing WebView (if ready)
        if isEditorReady, let webView = webView {
            loadContent(into: webView)
        }
    }
    
    private func loadContent(into webView: WKWebView) {
        // Load JSON content if available
        if let contentData = document.content,
           let jsonString = String(data: contentData, encoding: .utf8),
           !jsonString.isEmpty && jsonString != "{}" {
            let escapedJSON = jsonString
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
            webView.evaluateJavaScript("editorBridge.setContentJSON('\(escapedJSON)')")
        } else if !document.plainText.isEmpty {
            // Fallback to plain text
            let escapedText = document.plainText
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "</p><p>")
            webView.evaluateJavaScript("editorBridge.setContent('<p>\(escapedText)</p>')")
        } else {
            // Empty document
            webView.evaluateJavaScript("editorBridge.setContent('<p></p>')")
        }
        
        // Focus the editor
        webView.evaluateJavaScript("editorBridge.focus()")
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
    
    private func setupKeyboardShortcuts() {
        // Register keyboard shortcuts via NSEvent monitor
        // These will forward to the TipTap editor
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let webView = webView else { return event }
            
            let flags = event.modifierFlags
            let isCmd = flags.contains(.command)
            let isShift = flags.contains(.shift)
            let isOpt = flags.contains(.option)
            
            // Only handle command key combinations
            guard isCmd else { return event }
            
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
            
            switch (key, isShift, isOpt) {
            // Text formatting
            case ("b", false, false): webView.toggleBold(); return nil
            case ("i", false, false): webView.toggleItalic(); return nil
            case ("u", false, false): webView.toggleUnderline(); return nil
            case ("e", false, false): webView.toggleCode(); return nil
            case ("k", false, false): showLinkDialog(); return nil
            case ("x", true, false): webView.toggleStrike(); return nil
            case ("h", true, false): webView.evaluateJavaScript("editorBridge.toggleHighlight()"); return nil
            
            // Headings
            case ("1", true, false): webView.toggleHeading1(); return nil
            case ("2", true, false): webView.toggleHeading2(); return nil
            case ("0", true, false): webView.setHeading(0); return nil
            
            // Lists
            case ("7", true, false): webView.toggleOrderedList(); return nil
            case ("8", true, false): webView.toggleBulletList(); return nil
            case ("9", true, false): webView.toggleTaskList(); return nil
            
            // Task Cards
            case ("t", true, false): webView.insertTaskCard(); return nil
            
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Show actual content preview if available
                if !document.plainText.isEmpty {
                    Text(document.plainText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(themeManager.tokens.colors.textPrimary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // Placeholder for empty documents
                    Text("Start writing...")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                
                Spacer(minLength: 100)
            }
            .padding(32)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - TipTap Editor View

struct TiptapEditorView: View {
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
    @Environment(\.autosaveManager) private var autosaveManager
    
    @State private var htmlContent: String = ""
    @State private var jsonContent: String = ""
    
    // Height for the formatting toolbar area (content will scroll behind this)
    private let toolbarAreaHeight: CGFloat = 52
    
    var body: some View {
        // ZStack overlay approach - content scrolls behind the toolbar
        ZStack(alignment: .top) {
            // Main editor content - extends into safe area for scroll-behind effect
            ZStack {
                // Skeleton shown while loading
                if !isEditorReady {
                    EditorSkeletonView(document: document)
                        .transition(.opacity)
                }
                
                // WebView always rendered (needs to load to become ready)
                TiptapWebView(
                    htmlContent: $htmlContent,
                    jsonContent: $jsonContent,
                    onContentChange: { html, json, text in
                        wordCount = text.isEmpty ? 0 : text.split(separator: " ").count
                        autosaveManager.contentDidChange(
                            content: json.data(using: .utf8),
                            plainText: text,
                            wordCount: wordCount
                        )
                    },
                    onReady: {
                        print("📝 TipTap editor ready!")
                        withAnimation(.easeOut(duration: 0.15)) {
                            isEditorReady = true
                        }
                        loadDocumentContent()
                    },
                    onSelectionChange: { state in
                        editorState = state
                    },
                    themeCSS: themeCSS,
                    webViewRef: $webView
                )
                .opacity(isEditorReady ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Formatting toolbar - respects safe area, sits below window toolbar
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
        .onAppear {
            autosaveManager.startEditing(document)
        }
        .onDisappear {
            autosaveManager.stopEditing()
        }
    }
    
    // MARK: - Content Loading
    
    private func loadDocumentContent() {
        guard let webView = webView else {
            print("⚠️ WebView not available for content loading")
            return
        }
        
        // Try to load JSON content first (preferred format)
        if let contentData = document.content,
           let jsonString = String(data: contentData, encoding: .utf8),
           !jsonString.isEmpty && jsonString != "{}" {
            print("📄 Loading JSON content for document: \(document.displayTitle)")
            let escapedJSON = jsonString
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
            webView.evaluateJavaScript("editorBridge.setContentJSON('\(escapedJSON)')") { _, error in
                if let error = error {
                    print("❌ Error setting JSON content: \(error)")
                } else {
                    print("✅ JSON content loaded successfully")
                }
            }
        } else if !document.plainText.isEmpty {
            // Fallback to plain text if no JSON content
            print("📄 Loading plain text content for document: \(document.displayTitle)")
            let escapedText = document.plainText
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "</p><p>")
            webView.evaluateJavaScript("editorBridge.setContent('<p>\(escapedText)</p>')") { _, error in
                if let error = error {
                    print("❌ Error setting plain text content: \(error)")
                }
            }
        } else {
            print("📄 No existing content for document: \(document.displayTitle)")
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
                            // If highlight is active and this group comes after the highlight group, add extra offset
                            if editorState.isHighlight, let highlightIndex = highlightGroupIndex, index > highlightIndex {
                                offset += 1 // Extra offset to merge with color picker
                            }
                            return mergeOffset * offset
                        }()
                        
                        toolGroup(tools)
                            .glassEffect(.regular, in: .capsule)
                            .offset(x: groupOffset)
                        
                        // Insert highlight color picker right after the group containing highlight
                        if (editorState.isHighlight || showColorPicker) && index == highlightGroupIndex {
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
                    let overflowOffset = config.groups.count + (editorState.isHighlight && highlightGroupIndex != nil ? 1 : 0)
                    overflowButton
                        .glassEffect(.regular, in: .capsule)
                        .offset(x: mergeOffset * CGFloat(overflowOffset))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: editorState.isHighlight)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: config.groups.count)
            .onChange(of: editorState.isHighlight) { oldValue, newValue in
                if newValue && !showColorPicker {
                    // Show color picker and cascade colors in
                    showColorPicker = true
                    visibleColorCount = 0
                    // Cascade colors in with delay
                    for i in 0..<6 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                            if showColorPicker { // Only update if still showing
                                visibleColorCount = i + 1
                            }
                        }
                    }
                } else if !newValue && showColorPicker {
                    // Cascade colors out with overlapping timing for smoother cascade
                    for i in (0..<6).reversed() {
                        // Overlap animations: each starts before previous finishes (20ms delay instead of 50ms)
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(6 - i - 1) * 0.02) {
                            visibleColorCount = i
                        }
                    }
                    // Hide picker after all animations complete (6 colors × 20ms + buffer)
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(6) * 0.02 + 0.15) {
                        showColorPicker = false
                        visibleColorCount = 0
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
                let isSelected = editorState.highlightColor.lowercased() == colorInfo.color.toHex()?.lowercased()
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
            webView.setHeading(0)
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
            // Immediately show color picker when highlight button is clicked (before state update)
            let wasHighlighted = editorState.isHighlight
            webView.evaluateJavaScript("editorBridge.toggleHighlight()")
            
            // If we're toggling highlight ON (wasn't highlighted before), show colors immediately
            if !wasHighlighted {
                showColorPicker = true
                visibleColorCount = 0
                // Cascade colors in
                for i in 0..<6 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                        if showColorPicker {
                            visibleColorCount = i + 1
                        }
                    }
                }
            } else {
                // If toggling OFF, hide immediately (state will update from JS)
                showColorPicker = false
                visibleColorCount = 0
            }
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
            document.updatedAt = Date()
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
