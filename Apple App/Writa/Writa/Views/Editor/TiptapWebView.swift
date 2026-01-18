//
//  TiptapWebView.swift
//  Writa
//
//  WKWebView wrapper for embedding the TipTap rich text editor.
//  Provides bidirectional communication between Swift and JavaScript.
//

import SwiftUI
import WebKit

// MARK: - TiptapWebView

struct TiptapWebView: NSViewRepresentable {
    @Binding var htmlContent: String
    @Binding var jsonContent: String
    var onContentChange: ((String, String, String) -> Void)?  // html, json, plainText
    var onReady: (() -> Void)?
    var onSelectionChange: ((EditorState) -> Void)?
    var themeCSS: String?
    
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
        
        // Load the local HTML file
        loadEditor(in: webView)
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Inject theme CSS if provided and changed
        if let css = themeCSS, context.coordinator.lastInjectedCSS != css {
            context.coordinator.lastInjectedCSS = css
            let escapedCSS = css.replacingOccurrences(of: "\\", with: "\\\\")
                                .replacingOccurrences(of: "'", with: "\\'")
                                .replacingOccurrences(of: "\n", with: "\\n")
            nsView.evaluateJavaScript("editorBridge.setThemeCSS('\(escapedCSS)')")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func loadEditor(in webView: WKWebView) {
        do {
            // Try to load local HTML file
            if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Editor") {
                let htmlString = try String(contentsOf: htmlURL, encoding: .utf8)
                let baseURL = htmlURL.deletingLastPathComponent()
                webView.loadHTMLString(htmlString, baseURL: baseURL)
                return
            }
            
            // Try root bundle
            if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html") {
                let htmlString = try String(contentsOf: htmlURL, encoding: .utf8)
                let baseURL = htmlURL.deletingLastPathComponent()
                webView.loadHTMLString(htmlString, baseURL: baseURL)
                return
            }
        } catch {
            print("❌ Error loading HTML file: \(error.localizedDescription)")
        }
        
        // Final fallback: inline HTML with CDN
        print("⚠️ Loading inline fallback with CDN")
        let inlineHTML = Self.generateInlineHTML()
        webView.loadHTMLString(inlineHTML, baseURL: nil)
    }
    
    /// Generates inline HTML with TipTap editor when bundle files aren't available
    /// Uses jsdelivr CDN with UMD bundles for maximum compatibility
    private static func generateInlineHTML() -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Writa Editor</title>
            <style id="theme-styles"></style>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { height: 100%; width: 100%; overflow: hidden; background: transparent; }
                #editor { height: 100%; width: 100%; overflow-y: auto; padding: 32px; }
                .tiptap { outline: none; min-height: 100%; max-width: 720px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 16px; line-height: 1.6; color: #333; }
                .tiptap:focus { outline: none; }
                .tiptap > p:first-child.is-empty::before { content: 'Start writing...'; float: left; color: #999; pointer-events: none; height: 0; }
                .tiptap p { margin-bottom: 1em; }
                .tiptap h1 { font-size: 2em; font-weight: 700; margin-bottom: 0.5em; margin-top: 1em; }
                .tiptap h2 { font-size: 1.5em; font-weight: 600; margin-bottom: 0.5em; margin-top: 1em; }
                .tiptap h3 { font-size: 1.25em; font-weight: 600; margin-bottom: 0.5em; margin-top: 1em; }
                .tiptap strong { font-weight: 600; }
                .tiptap em { font-style: italic; }
                .tiptap u { text-decoration: underline; }
                .tiptap s { text-decoration: line-through; }
                .tiptap code { background: rgba(0,0,0,0.05); border-radius: 4px; padding: 0.2em 0.4em; font-family: ui-monospace, monospace; font-size: 0.9em; }
                .tiptap pre { background: rgba(0,0,0,0.05); border-radius: 8px; padding: 16px; margin: 1em 0; overflow-x: auto; }
                .tiptap pre code { background: none; padding: 0; }
                .tiptap blockquote { border-left: 3px solid #007AFF; padding-left: 16px; margin: 1em 0; color: #666; }
                .tiptap ul, .tiptap ol { padding-left: 24px; margin: 1em 0; }
                .tiptap li { margin-bottom: 0.25em; }
                .tiptap ul[data-type="taskList"] { list-style: none; padding-left: 0; }
                .tiptap ul[data-type="taskList"] li { display: flex; align-items: flex-start; gap: 8px; }
                .tiptap ul[data-type="taskList"] li input[type="checkbox"] { margin-top: 4px; cursor: pointer; }
                .tiptap a { color: #007AFF; text-decoration: none; }
                .tiptap a:hover { text-decoration: underline; }
                .tiptap img { max-width: 100%; height: auto; border-radius: 8px; margin: 1em 0; }
                .tiptap hr { border: none; border-top: 1px solid #ddd; margin: 2em 0; }
                .tiptap ::selection { background: rgba(0, 122, 255, 0.2); }
                #editor::-webkit-scrollbar { width: 8px; }
                #editor::-webkit-scrollbar-track { background: transparent; }
                #editor::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.2); border-radius: 4px; }
                #status { padding: 20px; text-align: center; color: #999; font-family: -apple-system, sans-serif; }
                .error { color: #ff3b30; }
                @media (prefers-color-scheme: dark) {
                    .tiptap { color: #f0f0f0; }
                    .tiptap code { background: rgba(255,255,255,0.1); }
                    .tiptap pre { background: rgba(255,255,255,0.1); }
                    .tiptap blockquote { color: #aaa; }
                }
            </style>
        </head>
        <body>
            <div id="editor"></div>
            <div id="status">Loading editor...</div>
            
            <script>
                // Simple communication bridge
                function sendToSwift(message) {
                    try {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.tiptap) {
                            window.webkit.messageHandlers.tiptap.postMessage(message);
                        }
                    } catch (e) {
                        console.error('Error sending to Swift:', e);
                    }
                }
                
                function updateStatus(text, isError) {
                    var el = document.getElementById('status');
                    if (el) {
                        el.textContent = text;
                        el.className = isError ? 'error' : '';
                    }
                }
                
                function getEditorState() {
                    if (!window.editor) return {};
                    var e = window.editor;
                    return {
                        isBold: e.isActive('bold'),
                        isItalic: e.isActive('italic'),
                        isUnderline: e.isActive('underline'),
                        isStrike: e.isActive('strike'),
                        isCode: e.isActive('code'),
                        isCodeBlock: e.isActive('codeBlock'),
                        isBlockquote: e.isActive('blockquote'),
                        isBulletList: e.isActive('bulletList'),
                        isOrderedList: e.isActive('orderedList'),
                        isTaskList: e.isActive('taskList'),
                        headingLevel: e.isActive('heading', { level: 1 }) ? 1 : e.isActive('heading', { level: 2 }) ? 2 : e.isActive('heading', { level: 3 }) ? 3 : 0,
                        isLink: e.isActive('link'),
                        canUndo: e.can().undo(),
                        canRedo: e.can().redo()
                    };
                }
                
                function initEditor() {
                    updateStatus('Initializing editor...');
                    
                    try {
                        // Check if TipTap loaded
                        if (typeof window.TiptapCore === 'undefined') {
                            throw new Error('TipTap Core not loaded');
                        }
                        if (typeof window.TiptapStarterKit === 'undefined') {
                            throw new Error('TipTap StarterKit not loaded');
                        }
                        
                        var Editor = window.TiptapCore.Editor;
                        var StarterKit = window.TiptapStarterKit.StarterKit || window.TiptapStarterKit.default || window.TiptapStarterKit;
                        var Underline = window.TiptapUnderline ? (window.TiptapUnderline.Underline || window.TiptapUnderline.default || window.TiptapUnderline) : null;
                        var Link = window.TiptapLink ? (window.TiptapLink.Link || window.TiptapLink.default || window.TiptapLink) : null;
                        var TaskList = window.TiptapTaskList ? (window.TiptapTaskList.TaskList || window.TiptapTaskList.default || window.TiptapTaskList) : null;
                        var TaskItem = window.TiptapTaskItem ? (window.TiptapTaskItem.TaskItem || window.TiptapTaskItem.default || window.TiptapTaskItem) : null;
                        
                        var extensions = [
                            StarterKit.configure({ heading: { levels: [1, 2, 3] } })
                        ];
                        
                        if (Underline) extensions.push(Underline);
                        if (Link) extensions.push(Link.configure({ openOnClick: false }));
                        if (TaskList) extensions.push(TaskList);
                        if (TaskItem) extensions.push(TaskItem.configure({ nested: true }));
                        
                        var editor = new Editor({
                            element: document.getElementById('editor'),
                            extensions: extensions,
                            content: '<p></p>',
                            editorProps: { 
                                attributes: { class: 'tiptap' }
                            },
                            onUpdate: function(props) {
                                sendToSwift({ 
                                    type: 'contentChange', 
                                    html: props.editor.getHTML(), 
                                    json: props.editor.getJSON(), 
                                    text: props.editor.getText() 
                                });
                            },
                            onSelectionUpdate: function() {
                                sendToSwift({ type: 'selectionChange', state: getEditorState() });
                            },
                            onFocus: function() { sendToSwift({ type: 'focus' }); },
                            onBlur: function() { sendToSwift({ type: 'blur' }); }
                        });
                        
                        window.editor = editor;
                        
                        // Editor bridge for Swift commands
                        window.editorBridge = {
                            setContent: function(html) { editor.commands.setContent(html || '<p></p>'); },
                            setContentJSON: function(json) { if (json) editor.commands.setContent(json); },
                            getContent: function() { return editor.getHTML(); },
                            getContentJSON: function() { return JSON.stringify(editor.getJSON()); },
                            getText: function() { return editor.getText(); },
                            toggleBold: function() { editor.chain().focus().toggleBold().run(); },
                            toggleItalic: function() { editor.chain().focus().toggleItalic().run(); },
                            toggleUnderline: function() { editor.chain().focus().toggleUnderline().run(); },
                            toggleStrike: function() { editor.chain().focus().toggleStrike().run(); },
                            toggleCode: function() { editor.chain().focus().toggleCode().run(); },
                            setHeading: function(level) { 
                                if (level === 0) editor.chain().focus().setParagraph().run();
                                else editor.chain().focus().toggleHeading({ level: level }).run();
                            },
                            toggleHeading1: function() { editor.chain().focus().toggleHeading({ level: 1 }).run(); },
                            toggleHeading2: function() { editor.chain().focus().toggleHeading({ level: 2 }).run(); },
                            toggleHeading3: function() { editor.chain().focus().toggleHeading({ level: 3 }).run(); },
                            toggleBulletList: function() { editor.chain().focus().toggleBulletList().run(); },
                            toggleOrderedList: function() { editor.chain().focus().toggleOrderedList().run(); },
                            toggleTaskList: function() { editor.chain().focus().toggleTaskList().run(); },
                            toggleBlockquote: function() { editor.chain().focus().toggleBlockquote().run(); },
                            toggleCodeBlock: function() { editor.chain().focus().toggleCodeBlock().run(); },
                            setHorizontalRule: function() { editor.chain().focus().setHorizontalRule().run(); },
                            setLink: function(url) { if (url) editor.chain().focus().setLink({ href: url }).run(); },
                            unsetLink: function() { editor.chain().focus().unsetLink().run(); },
                            undo: function() { editor.chain().focus().undo().run(); },
                            redo: function() { editor.chain().focus().redo().run(); },
                            focus: function() { editor.commands.focus(); },
                            blur: function() { editor.commands.blur(); },
                            getState: function() { return JSON.stringify(getEditorState()); },
                            setThemeCSS: function(css) { 
                                var el = document.getElementById('theme-styles'); 
                                if (el) el.textContent = css; 
                            }
                        };
                        
                        // Hide status, show editor
                        document.getElementById('status').style.display = 'none';
                        
                        // Focus the editor
                        setTimeout(function() { editor.commands.focus(); }, 100);
                        
                        // Notify Swift
                        sendToSwift({ type: 'ready' });
                        
                    } catch (err) {
                        updateStatus('Error: ' + err.message, true);
                        console.error('Editor init error:', err);
                    }
                }
                
                // Track script loading (pm is bundled with core, not loaded separately)
                var scriptsToLoad = 6;
                var scriptsLoaded = 0;
                var scriptErrors = [];
                
                function onScriptLoad() {
                    scriptsLoaded++;
                    updateStatus('Loading... (' + scriptsLoaded + '/' + scriptsToLoad + ')');
                    if (scriptsLoaded >= scriptsToLoad) {
                        if (scriptErrors.length > 0) {
                            updateStatus('Failed to load: ' + scriptErrors.join(', '), true);
                        } else {
                            initEditor();
                        }
                    }
                }
                
                function onScriptError(name) {
                    scriptsLoaded++;
                    scriptErrors.push(name);
                    updateStatus('Loading... (' + scriptsLoaded + '/' + scriptsToLoad + ')');
                    if (scriptsLoaded >= scriptsToLoad) {
                        if (scriptErrors.length > 0) {
                            updateStatus('Failed to load: ' + scriptErrors.join(', '), true);
                        } else {
                            initEditor();
                        }
                    }
                }
            </script>
            
            <!-- Load TipTap UMD bundles from CDN (pm is bundled with core) -->
            <script src="https://cdn.jsdelivr.net/npm/@tiptap/core@2.1.13/dist/index.umd.js" onload="window.TiptapCore = window['@tiptap/core']; onScriptLoad();" onerror="onScriptError('core');"></script>
            <script src="https://cdn.jsdelivr.net/npm/@tiptap/starter-kit@2.1.13/dist/index.umd.js" onload="window.TiptapStarterKit = window['@tiptap/starter-kit']; onScriptLoad();" onerror="onScriptError('starter-kit');"></script>
            <script src="https://cdn.jsdelivr.net/npm/@tiptap/extension-underline@2.1.13/dist/index.umd.js" onload="window.TiptapUnderline = window['@tiptap/extension-underline']; onScriptLoad();" onerror="onScriptError('underline');"></script>
            <script src="https://cdn.jsdelivr.net/npm/@tiptap/extension-link@2.1.13/dist/index.umd.js" onload="window.TiptapLink = window['@tiptap/extension-link']; onScriptLoad();" onerror="onScriptError('link');"></script>
            <script src="https://cdn.jsdelivr.net/npm/@tiptap/extension-task-list@2.1.13/dist/index.umd.js" onload="window.TiptapTaskList = window['@tiptap/extension-task-list']; onScriptLoad();" onerror="onScriptError('task-list');"></script>
            <script src="https://cdn.jsdelivr.net/npm/@tiptap/extension-task-item@2.1.13/dist/index.umd.js" onload="window.TiptapTaskItem = window['@tiptap/extension-task-item']; onScriptLoad();" onerror="onScriptError('task-item');"></script>
        </body>
        </html>
        """
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: TiptapWebView
        var isEditorReady = false
        var pendingContent: String?
        var lastInjectedCSS: String?
        
        init(_ parent: TiptapWebView) {
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
            case "ready":
                print("📝 TipTap editor ready!")
                isEditorReady = true
                
                // Set initial content if available
                if !parent.htmlContent.isEmpty {
                    setContent(parent.htmlContent)
                }
                
                // Inject theme CSS
                if let css = parent.themeCSS {
                    injectThemeCSS(css)
                }
                
                parent.onReady?()
                
            case "contentChange":
                let html = body["html"] as? String ?? ""
                let json = body["json"] as? [String: Any] ?? [:]
                let text = body["text"] as? String ?? ""
                
                // Convert JSON to string
                let jsonString: String
                if let jsonData = try? JSONSerialization.data(withJSONObject: json),
                   let jsonStr = String(data: jsonData, encoding: .utf8) {
                    jsonString = jsonStr
                } else {
                    jsonString = "{}"
                }
                
                DispatchQueue.main.async {
                    self.parent.htmlContent = html
                    self.parent.jsonContent = jsonString
                    self.parent.onContentChange?(html, jsonString, text)
                }
                
            case "selectionChange":
                if let stateDict = body["state"] as? [String: Any] {
                    let state = EditorState(from: stateDict)
                    DispatchQueue.main.async {
                        self.parent.onSelectionChange?(state)
                    }
                }
                
            case "focus":
                // Editor gained focus
                break
                
            case "blur":
                // Editor lost focus
                break
                
            case "debug":
                if let debugMessage = body["message"] as? String {
                    print("🐛 JS Debug: \(debugMessage)")
                }
                
            default:
                print("⚠️ Unknown message type: \(type)")
                break
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WebView provisional navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("📝 WebView started loading...")
        }
        
        // MARK: - Helper Methods
        
        private func setContent(_ html: String) {
            guard let webView = parent.webViewRef else { return }
            let escapedHTML = html.replacingOccurrences(of: "\\", with: "\\\\")
                                  .replacingOccurrences(of: "'", with: "\\'")
                                  .replacingOccurrences(of: "\n", with: "\\n")
            webView.evaluateJavaScript("editorBridge.setContent('\(escapedHTML)')")
        }
        
        private func injectThemeCSS(_ css: String) {
            guard let webView = parent.webViewRef else { return }
            let escapedCSS = css.replacingOccurrences(of: "\\", with: "\\\\")
                                .replacingOccurrences(of: "'", with: "\\'")
                                .replacingOccurrences(of: "\n", with: "\\n")
            webView.evaluateJavaScript("editorBridge.setThemeCSS('\(escapedCSS)')")
            lastInjectedCSS = css
        }
    }
}

// MARK: - Editor State

struct EditorState {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrike: Bool = false
    var isCode: Bool = false
    var isCodeBlock: Bool = false
    var isBlockquote: Bool = false
    var isBulletList: Bool = false
    var isOrderedList: Bool = false
    var isTaskList: Bool = false
    var isHighlight: Bool = false
    var isSubscript: Bool = false
    var isSuperscript: Bool = false
    var headingLevel: Int = 0
    var isLink: Bool = false
    var textAlign: String = "left"
    var canUndo: Bool = false
    var canRedo: Bool = false
    
    init() {}
    
    init(from dict: [String: Any]) {
        isBold = dict["isBold"] as? Bool ?? false
        isItalic = dict["isItalic"] as? Bool ?? false
        isUnderline = dict["isUnderline"] as? Bool ?? false
        isStrike = dict["isStrike"] as? Bool ?? false
        isCode = dict["isCode"] as? Bool ?? false
        isCodeBlock = dict["isCodeBlock"] as? Bool ?? false
        isBlockquote = dict["isBlockquote"] as? Bool ?? false
        isBulletList = dict["isBulletList"] as? Bool ?? false
        isOrderedList = dict["isOrderedList"] as? Bool ?? false
        isTaskList = dict["isTaskList"] as? Bool ?? false
        isHighlight = dict["isHighlight"] as? Bool ?? false
        isSubscript = dict["isSubscript"] as? Bool ?? false
        isSuperscript = dict["isSuperscript"] as? Bool ?? false
        headingLevel = dict["headingLevel"] as? Int ?? 0
        isLink = dict["isLink"] as? Bool ?? false
        textAlign = dict["textAlign"] as? String ?? "left"
        canUndo = dict["canUndo"] as? Bool ?? false
        canRedo = dict["canRedo"] as? Bool ?? false
    }
}

// MARK: - Editor Commands

extension WKWebView {
    // Text Formatting
    func toggleBold() { evaluateJavaScript("editorBridge.toggleBold()") }
    func toggleItalic() { evaluateJavaScript("editorBridge.toggleItalic()") }
    func toggleUnderline() { evaluateJavaScript("editorBridge.toggleUnderline()") }
    func toggleStrike() { evaluateJavaScript("editorBridge.toggleStrike()") }
    func toggleCode() { evaluateJavaScript("editorBridge.toggleCode()") }
    
    // Headings
    func setHeading(_ level: Int) { evaluateJavaScript("editorBridge.setHeading(\(level))") }
    func toggleHeading1() { evaluateJavaScript("editorBridge.toggleHeading1()") }
    func toggleHeading2() { evaluateJavaScript("editorBridge.toggleHeading2()") }
    func toggleHeading3() { evaluateJavaScript("editorBridge.toggleHeading3()") }
    
    // Lists
    func toggleBulletList() { evaluateJavaScript("editorBridge.toggleBulletList()") }
    func toggleOrderedList() { evaluateJavaScript("editorBridge.toggleOrderedList()") }
    func toggleTaskList() { evaluateJavaScript("editorBridge.toggleTaskList()") }
    
    // Blocks
    func toggleBlockquote() { evaluateJavaScript("editorBridge.toggleBlockquote()") }
    func toggleCodeBlock() { evaluateJavaScript("editorBridge.toggleCodeBlock()") }
    
    // Links & Images
    func setLink(_ url: String) {
        let escaped = url.replacingOccurrences(of: "'", with: "\\'")
        evaluateJavaScript("editorBridge.setLink('\(escaped)')")
    }
    func removeLink() { evaluateJavaScript("editorBridge.unsetLink()") }
    func insertImage(_ src: String, alt: String = "") {
        let escapedSrc = src.replacingOccurrences(of: "'", with: "\\'")
        let escapedAlt = alt.replacingOccurrences(of: "'", with: "\\'")
        evaluateJavaScript("editorBridge.insertImage('\(escapedSrc)', '\(escapedAlt)')")
    }
    
    // History
    func editorUndo() { evaluateJavaScript("editorBridge.undo()") }
    func editorRedo() { evaluateJavaScript("editorBridge.redo()") }
    
    // Focus
    func focusEditor() { evaluateJavaScript("editorBridge.focus()") }
    func blurEditor() { evaluateJavaScript("editorBridge.blur()") }
    
    // Content
    func setEditorContent(_ html: String) {
        let escaped = html.replacingOccurrences(of: "\\", with: "\\\\")
                          .replacingOccurrences(of: "'", with: "\\'")
                          .replacingOccurrences(of: "\n", with: "\\n")
        evaluateJavaScript("editorBridge.setContent('\(escaped)')")
    }
}
