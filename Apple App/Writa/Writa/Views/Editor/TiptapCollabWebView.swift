//
//  TiptapCollabWebView.swift
//  Writa
//
//  Collaborative TipTap editor using Yjs and PartyKit.
//  This version syncs document content AND metadata via Yjs CRDTs.
//

import SwiftUI
import WebKit

// MARK: - Configuration

struct CollabConfig {
    static var partyKitHost = "writa-collab.jmaorr.partykit.dev"
}

// MARK: - Editor State

/// Tracks the current formatting state of the editor selection
struct EditorState {
    var isBold = false
    var isItalic = false
    var isUnderline = false
    var isStrikethrough = false
    var isStrike = false  // Alias for isStrikethrough
    var isCode = false
    var isLink = false
    var isBulletList = false
    var isOrderedList = false
    var isTaskList = false
    var isTaskCard = false
    var isBlockquote = false
    var isCodeBlock = false
    var isHighlight = false
    var isSubscript = false
    var isSuperscript = false
    var headingLevel: Int = 0  // 0 = paragraph, 1-6 = heading levels
    var textColor: String?
    var highlightColor: String?
    var textAlign: String = "left"
    var fontSize: String?
    var fontFamily: String?
    
    init() {}
    
    init(from dict: [String: Any]) {
        isBold = dict["isBold"] as? Bool ?? false
        isItalic = dict["isItalic"] as? Bool ?? false
        isUnderline = dict["isUnderline"] as? Bool ?? false
        isStrikethrough = dict["isStrikethrough"] as? Bool ?? dict["isStrike"] as? Bool ?? false
        isStrike = isStrikethrough
        isCode = dict["isCode"] as? Bool ?? false
        isLink = dict["isLink"] as? Bool ?? false
        isBulletList = dict["isBulletList"] as? Bool ?? false
        isOrderedList = dict["isOrderedList"] as? Bool ?? false
        isTaskList = dict["isTaskList"] as? Bool ?? false
        isTaskCard = dict["isTaskCard"] as? Bool ?? false
        isBlockquote = dict["isBlockquote"] as? Bool ?? false
        isCodeBlock = dict["isCodeBlock"] as? Bool ?? false
        isHighlight = (dict["isHighlight"] as? Bool) ?? ((dict["highlightColor"] as? String) != nil)
        isSubscript = dict["isSubscript"] as? Bool ?? false
        isSuperscript = dict["isSuperscript"] as? Bool ?? false
        headingLevel = dict["headingLevel"] as? Int ?? 0
        textColor = dict["textColor"] as? String
        highlightColor = dict["highlightColor"] as? String
        textAlign = dict["textAlign"] as? String ?? "left"
        fontSize = dict["fontSize"] as? String
        fontFamily = dict["fontFamily"] as? String
    }
}

// MARK: - WKWebView Editor Commands Extension

extension WKWebView {
    // MARK: - Text Formatting
    
    func toggleBold() {
        evaluateJavaScript("editorBridge.toggleBold()")
    }
    
    func toggleItalic() {
        evaluateJavaScript("editorBridge.toggleItalic()")
    }
    
    func toggleUnderline() {
        evaluateJavaScript("editorBridge.toggleUnderline()")
    }
    
    func toggleStrike() {
        evaluateJavaScript("editorBridge.toggleStrike()")
    }
    
    func toggleCode() {
        evaluateJavaScript("editorBridge.toggleCode()")
    }
    
    func toggleHighlight(color: String? = nil) {
        if let color = color {
            evaluateJavaScript("editorBridge.toggleHighlight('\(color)')")
        } else {
            evaluateJavaScript("editorBridge.toggleHighlight()")
        }
    }
    
    func toggleSubscript() {
        evaluateJavaScript("editorBridge.toggleSubscript()")
    }
    
    func toggleSuperscript() {
        evaluateJavaScript("editorBridge.toggleSuperscript()")
    }
    
    // MARK: - Headings
    
    func toggleHeading1() {
        evaluateJavaScript("editorBridge.toggleHeading(1)")
    }
    
    func toggleHeading2() {
        evaluateJavaScript("editorBridge.toggleHeading(2)")
    }
    
    func toggleHeading3() {
        evaluateJavaScript("editorBridge.toggleHeading(3)")
    }
    
    func setHeading(level: Int) {
        evaluateJavaScript("editorBridge.toggleHeading(\(level))")
    }
    
    func setParagraph() {
        evaluateJavaScript("editorBridge.setParagraph()")
    }
    
    // MARK: - Lists
    
    func toggleBulletList() {
        evaluateJavaScript("editorBridge.toggleBulletList()")
    }
    
    func toggleOrderedList() {
        evaluateJavaScript("editorBridge.toggleOrderedList()")
    }
    
    func toggleTaskList() {
        evaluateJavaScript("editorBridge.toggleTaskList()")
    }
    
    // MARK: - Blocks
    
    func toggleBlockquote() {
        evaluateJavaScript("editorBridge.toggleBlockquote()")
    }
    
    func toggleCodeBlock() {
        evaluateJavaScript("editorBridge.toggleCodeBlock()")
    }
    
    func insertHorizontalRule() {
        evaluateJavaScript("editorBridge.insertHorizontalRule()")
    }
    
    // MARK: - Custom Extensions
    
    func insertTaskCard() {
        evaluateJavaScript("editorBridge.insertTaskCard()")
    }
    
    func insertPromptSnippet() {
        evaluateJavaScript("editorBridge.insertPromptSnippet()")
    }
    
    // MARK: - Links
    
    func setLink(url: String) {
        let escapedUrl = url.replacingOccurrences(of: "'", with: "\\'")
        evaluateJavaScript("editorBridge.setLink('\(escapedUrl)')")
    }
    
    func unsetLink() {
        evaluateJavaScript("editorBridge.unsetLink()")
    }
    
    // MARK: - Images
    
    func insertImage(src: String, alt: String = "", title: String = "") {
        let escapedSrc = src.replacingOccurrences(of: "'", with: "\\'")
        let escapedAlt = alt.replacingOccurrences(of: "'", with: "\\'")
        let escapedTitle = title.replacingOccurrences(of: "'", with: "\\'")
        evaluateJavaScript("editorBridge.insertImage('\(escapedSrc)', '\(escapedAlt)', '\(escapedTitle)')")
    }
    
    // MARK: - Text Color
    
    func setTextColor(_ color: String) {
        evaluateJavaScript("editorBridge.setTextColor('\(color)')")
    }
    
    func unsetTextColor() {
        evaluateJavaScript("editorBridge.unsetTextColor()")
    }
    
    // MARK: - Text Alignment
    
    func setTextAlign(_ alignment: String) {
        evaluateJavaScript("editorBridge.setTextAlign('\(alignment)')")
    }
    
    // MARK: - Font
    
    func setFontFamily(_ fontFamily: String) {
        evaluateJavaScript("editorBridge.setFontFamily('\(fontFamily)')")
    }
    
    func setFontSize(_ size: String) {
        evaluateJavaScript("editorBridge.setFontSize('\(size)')")
    }
    
    // MARK: - Editor Control
    
    func focusEditor() {
        evaluateJavaScript("editorBridge.focus()")
    }
    
    func clearContent() {
        evaluateJavaScript("editorBridge.clearContent()")
    }
    
    func undo() {
        evaluateJavaScript("editorBridge.undo()")
    }
    
    func redo() {
        evaluateJavaScript("editorBridge.redo()")
    }
}

// MARK: - TiptapCollabWebView

struct TiptapCollabWebView: NSViewRepresentable {
    let documentId: UUID
    var userId: String?
    var userName: String?
    var userColor: String?
    var themeCSS: String?
    
    // Callbacks
    var onReady: (() -> Void)?
    var onContentChange: ((String, String, Data?) -> Void)?  // (plainText, title, jsonContent) for document list update and task extraction
    var onMetaChange: ((DocumentMeta) -> Void)?
    var onConnectionChange: ((ConnectionStatus) -> Void)?
    var onSelectionChange: ((EditorState) -> Void)?
    
    // Reference to the WebView for external access
    @Binding var webViewRef: WKWebView?
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Setup script message handler for JS -> Swift communication
        config.userContentController.add(context.coordinator, name: "tiptap")
        
        // Allow file access for local resources
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // Enable content JavaScript for local files
        if #available(macOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        // Make background transparent
        webView.setValue(false, forKey: "drawsBackground")
        
        // Enable inspector for debugging
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        
        // Store reference
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        
        // Load the collaborative editor HTML
        loadCollaborativeEditor(in: webView)
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update parent reference so coordinator has latest config
        context.coordinator.parent = self
        
        // Check if document changed - need to reinitialize Yjs for new document
        if context.coordinator.isEditorLoaded && context.coordinator.currentDocumentId != documentId {
            print("📝 Document changed from \(context.coordinator.currentDocumentId?.uuidString ?? "none") to \(documentId.uuidString)")
            context.coordinator.initializeDocument(for: documentId, webView: nsView)
        }
        
        // Inject theme CSS if provided and changed
        if let css = themeCSS, context.coordinator.lastInjectedCSS != css {
            context.coordinator.lastInjectedCSS = css
            
            if context.coordinator.isEditorReady {
                injectThemeCSS(css, in: nsView)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Load Editor
    
    private func loadCollaborativeEditor(in webView: WKWebView) {
        // Try to load collaborative HTML file
        // Use loadFileURL instead of loadHTMLString to allow local ES module imports
        if let htmlURL = Bundle.main.url(forResource: "index-collab", withExtension: "html", subdirectory: "Editor") {
            let baseURL = htmlURL.deletingLastPathComponent()
            // loadFileURL allows the WebView to access local files (like vendor/collab-bundle.js)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: baseURL)
            print("📝 Loading collaborative editor from: \(htmlURL.path)")
            return
        }
        
        // Try root bundle
        if let htmlURL = Bundle.main.url(forResource: "index-collab", withExtension: "html") {
            let baseURL = htmlURL.deletingLastPathComponent()
            webView.loadFileURL(htmlURL, allowingReadAccessTo: baseURL)
            print("📝 Loading collaborative editor from root: \(htmlURL.path)")
            return
        }
        
        print("❌ Collaborative editor HTML not found in bundle")
        
        // Fallback to regular editor if collaborative version not found
        print("⚠️ Collaborative editor not found, falling back to regular editor")
        loadRegularEditor(in: webView)
    }
    
    private func loadRegularEditor(in webView: WKWebView) {
        if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Editor") {
            do {
                let htmlString = try String(contentsOf: htmlURL, encoding: .utf8)
                let baseURL = htmlURL.deletingLastPathComponent()
                webView.loadHTMLString(htmlString, baseURL: baseURL)
            } catch {
                print("❌ Error loading regular editor: \(error)")
            }
        }
    }
    
    private func injectThemeCSS(_ css: String, in webView: WKWebView) {
        let escapedCSS = css.replacingOccurrences(of: "\\", with: "\\\\")
                            .replacingOccurrences(of: "'", with: "\\'")
                            .replacingOccurrences(of: "\n", with: "\\n")
        webView.evaluateJavaScript("editorBridge.setThemeCSS('\(escapedCSS)')") { _, error in
            if let error = error {
                print("⚠️ Error injecting theme CSS: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: TiptapCollabWebView
        var isEditorReady = false
        var isEditorLoaded = false
        var lastInjectedCSS: String?
        var currentDocumentId: UUID?  // Track which document is loaded
        
        init(_ parent: TiptapCollabWebView) {
            self.parent = parent
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "tiptap",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else {
                print("⚠️ Invalid message format or name")
                return
            }
            
            switch type {
            case "editorLoaded":
                // Editor HTML loaded, now initialize with document ID
                print("📝 Collaborative editor loaded, initializing...")
                isEditorLoaded = true
                initializeDocument()
                
            case "ready":
                print("📝 TipTap editor ready with Yjs!")
                isEditorReady = true
                
                // Inject theme CSS
                if let css = lastInjectedCSS ?? parent.themeCSS,
                   let webView = parent.webViewRef {
                    parent.injectThemeCSS(css, in: webView)
                }
                
                parent.onReady?()
                
            case "contentChange":
                let text = body["text"] as? String ?? ""
                let title = body["title"] as? String ?? ""
                // Parse JSON content for task extraction
                var jsonData: Data?
                if let jsonDict = body["json"] as? [String: Any] {
                    jsonData = try? JSONSerialization.data(withJSONObject: jsonDict)
                }
                DispatchQueue.main.async {
                    self.parent.onContentChange?(text, title, jsonData)
                }
                
            case "metaChange":
                if let metaDict = body["meta"] as? [String: Any] {
                    let meta = DocumentMeta(from: metaDict)
                    DispatchQueue.main.async {
                        self.parent.onMetaChange?(meta)
                    }
                }
                
            case "connectionStatus":
                let status = body["status"] as? String ?? "disconnected"
                let connectionStatus = ConnectionStatus(rawValue: status) ?? .disconnected
                DispatchQueue.main.async {
                    self.parent.onConnectionChange?(connectionStatus)
                }
                
            case "selectionChange":
                if let stateDict = body["state"] as? [String: Any] {
                    let state = EditorState(from: stateDict)
                    DispatchQueue.main.async {
                        self.parent.onSelectionChange?(state)
                    }
                }
                
            case "debug":
                if let debugMessage = body["message"] as? String {
                    print("🐛 JS Debug: \(debugMessage)")
                }
                
            default:
                print("⚠️ Unknown message type: \(type)")
            }
        }
        
        // MARK: - Initialize Document
        
        private func initializeDocument() {
            guard let webView = parent.webViewRef else {
                print("⚠️ Cannot initialize document - webViewRef is nil")
                return
            }
            initializeDocument(for: parent.documentId, webView: webView)
        }
        
        func initializeDocument(for documentId: UUID, webView: WKWebView) {
            // Track which document we're initializing (do this FIRST to prevent duplicate calls)
            currentDocumentId = documentId
            
            let config: [String: Any] = [
                "partyKitHost": CollabConfig.partyKitHost,
                "userId": parent.userId ?? "",
                "userName": parent.userName ?? "Anonymous",
                "userColor": parent.userColor ?? "#007AFF"
            ]
            
            guard let configData = try? JSONSerialization.data(withJSONObject: config),
                  let configJson = String(data: configData, encoding: .utf8) else {
                print("❌ Failed to serialize config")
                return
            }
            
            let js = "initDocument('\(documentId.uuidString)', \(configJson))"
            print("📝 Calling: \(js)")
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    print("❌ Error initializing document: \(error.localizedDescription)")
                }
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("📝 WebView started loading...")
        }
    }
}

// MARK: - Document Metadata (from Yjs)

struct DocumentMeta {
    var title: String = ""
    var isDeleted: Bool = false
    var deletedAt: Date?
    var workspaceId: String?
    var tags: [String] = []
    var isFavorite: Bool = false
    var isPinned: Bool = false
    var createdAt: Date?
    var updatedAt: Date?
    
    init() {}
    
    init(from dict: [String: Any]) {
        title = dict["title"] as? String ?? ""
        isDeleted = dict["isDeleted"] as? Bool ?? false
        
        if let deletedAtMs = dict["deletedAt"] as? Double {
            deletedAt = Date(timeIntervalSince1970: deletedAtMs / 1000.0)
        }
        
        workspaceId = dict["workspaceId"] as? String
        tags = dict["tags"] as? [String] ?? []
        isFavorite = dict["isFavorite"] as? Bool ?? false
        isPinned = dict["isPinned"] as? Bool ?? false
        
        if let createdAtMs = dict["createdAt"] as? Double {
            createdAt = Date(timeIntervalSince1970: createdAtMs / 1000.0)
        }
        if let updatedAtMs = dict["updatedAt"] as? Double {
            updatedAt = Date(timeIntervalSince1970: updatedAtMs / 1000.0)
        }
    }
}

// MARK: - Connection Status

enum ConnectionStatus: String {
    case connected
    case disconnected
    case syncing
}

// MARK: - WebView Extensions for Collaborative Editor

extension WKWebView {
    // Metadata operations (via Yjs)
    func moveDocumentToTrash() {
        evaluateJavaScript("editorBridge.moveToTrash()")
    }
    
    func restoreDocument() {
        evaluateJavaScript("editorBridge.restore()")
    }
    
    func setDocumentWorkspace(_ workspaceId: String?) {
        if let id = workspaceId {
            evaluateJavaScript("editorBridge.setWorkspace('\(id)')")
        } else {
            evaluateJavaScript("editorBridge.setWorkspace(null)")
        }
    }
    
    func toggleDocumentFavorite() {
        evaluateJavaScript("editorBridge.toggleFavorite()")
    }
    
    func toggleDocumentPinned() {
        evaluateJavaScript("editorBridge.togglePinned()")
    }
    
    func setDocumentTags(_ tags: [String]) {
        if let tagsData = try? JSONSerialization.data(withJSONObject: tags),
           let tagsJson = String(data: tagsData, encoding: .utf8) {
            evaluateJavaScript("editorBridge.setTags(\(tagsJson))")
        }
    }
    
    // Connection management
    func disconnectCollab() {
        evaluateJavaScript("editorBridge.disconnect()")
    }
    
    func reconnectCollab() {
        evaluateJavaScript("editorBridge.reconnect()")
    }
}
