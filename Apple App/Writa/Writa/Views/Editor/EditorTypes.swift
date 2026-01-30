//
//  EditorTypes.swift
//  Writa
//
//  Shared types for the TipTap editor, used by both macOS and iOS.
//

import Foundation
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

    // MARK: - Metadata operations (via Yjs)

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

    // MARK: - Connection management

    func disconnectCollab() {
        evaluateJavaScript("editorBridge.disconnect()")
    }

    func reconnectCollab() {
        evaluateJavaScript("editorBridge.reconnect()")
    }

    // MARK: - Theme

    func setThemeCSS(_ css: String) {
        let escapedCSS = css.replacingOccurrences(of: "\\", with: "\\\\")
                            .replacingOccurrences(of: "'", with: "\\'")
                            .replacingOccurrences(of: "\n", with: "\\n")
        evaluateJavaScript("editorBridge.setThemeCSS('\(escapedCSS)')") { _, error in
            if let error = error {
                print("⚠️ Error injecting theme CSS: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Snippet Cleanup

    /// Remove corrupted/empty snippet lists from the document (syncs via Yjs)
    func removeCorruptedSnippets(completion: ((Bool) -> Void)? = nil) {
        evaluateJavaScript("editorBridge.removeCorruptedSnippets()") { result, error in
            if let error = error {
                print("❌ Error removing corrupted snippets: \(error.localizedDescription)")
                completion?(false)
            } else {
                let removed = result as? Bool ?? false
                print(removed ? "✅ Corrupted snippets removed" : "ℹ️ No corrupted snippets found")
                completion?(removed)
            }
        }
    }

    /// Remove ALL snippet lists from the document (nuclear option, syncs via Yjs)
    func removeAllSnippets(completion: ((Bool) -> Void)? = nil) {
        evaluateJavaScript("editorBridge.removeAllSnippets()") { result, error in
            if let error = error {
                print("❌ Error removing snippets: \(error.localizedDescription)")
                completion?(false)
            } else {
                let removed = result as? Bool ?? false
                print(removed ? "✅ All snippets removed" : "ℹ️ No snippets found")
                completion?(removed)
            }
        }
    }

    /// Heal structurally corrupted snippets (missing title/body)
    func healSnippets(completion: ((_ healed: Int, _ removed: Int) -> Void)? = nil) {
        evaluateJavaScript("editorBridge.healSnippets()") { result, error in
            if let error = error {
                print("❌ Error healing snippets: \(error.localizedDescription)")
                completion?(0, 0)
            } else if let dict = result as? [String: Any] {
                let healed = dict["healed"] as? Int ?? 0
                let removed = dict["removed"] as? Int ?? 0
                print("✅ Healed snippets: healed=\(healed), removed=\(removed)")
                completion?(healed, removed)
            } else {
                completion?(0, 0)
            }
        }
    }

    /// Debug: dump document structure to console
    func debugDocument() {
        evaluateJavaScript("editorBridge.debugDocument()") { result, error in
            if let error = error {
                print("❌ Error debugging document: \(error.localizedDescription)")
            } else if let dict = result as? [String: Any] {
                print("📄 Document debug: \(dict)")
            }
        }
    }
}

// MARK: - PartyKit API Service

/// Service for calling PartyKit HTTP API endpoints
enum PartyKitAPI {
    /// Reset document content on the server (clears corrupted state)
    static func resetDocument(documentId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let roomId = "doc-\(documentId.uuidString)"
        callAPI(roomId: roomId, action: "reset", completion: completion)
    }

    /// Remove all snippets from document on the server
    static func removeSnippets(documentId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let roomId = "doc-\(documentId.uuidString)"
        callAPI(roomId: roomId, action: "removeSnippets", completion: completion)
    }

    private static func callAPI(roomId: String, action: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://\(CollabConfig.partyKitHost)/parties/main/\(roomId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "PartyKitAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["action": action]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("🌐 PartyKit API: \(action) -> \(urlString)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ PartyKit API error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NSError(domain: "PartyKitAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                    return
                }

                if httpResponse.statusCode == 200 {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ PartyKit API success: \(json)")
                    }
                    completion(.success(()))
                } else {
                    let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                    print("❌ PartyKit API error (\(httpResponse.statusCode)): \(errorMessage)")
                    completion(.failure(NSError(domain: "PartyKitAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            }
        }.resume()
    }
}
