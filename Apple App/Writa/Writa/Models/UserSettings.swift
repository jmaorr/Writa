//
//  UserSettings.swift
//  Writa
//
//  Sync-ready user settings model.
//  All user preferences that should persist across devices.
//
//  Sync Strategy:
//  - Stored locally in UserDefaults for immediate access
//  - Synced to cloud when user is authenticated
//  - Conflict resolution: Last-write-wins with timestamp
//

import SwiftUI

// MARK: - User Settings

/// Complete user settings - Codable for cloud sync
struct UserSettings: Codable, Equatable {
    // MARK: - Metadata
    var version: Int = 1
    var updatedAt: Date = Date()
    var deviceId: String?  // For conflict resolution
    
    // MARK: - Appearance
    var themeMode: String = "system"  // system, light, dark
    var selectedThemeId: String = "default"
    var customTheme: EditorTheme?  // User's customizations (if any)
    
    // MARK: - Editor Preferences
    var editorToolbarItems: [String] = []  // Tool IDs in order
    var editorToolbarSeparators: [Int] = []  // Indices where separators appear
    var showWordCount: Bool = true
    var showCharacterCount: Bool = false
    var autosaveEnabled: Bool = true
    var spellCheckEnabled: Bool = true
    var grammarCheckEnabled: Bool = false
    
    // MARK: - Sidebar Preferences
    var sidebarCollapsed: Bool = false
    var defaultSidebarSection: String = "allDocuments"
    var showDocumentPreviews: Bool = true
    var sortOrder: String = "dateModified"
    
    // MARK: - Sync Preferences
    var syncEnabled: Bool = true
    var syncOnCellular: Bool = false
    var offlineModeEnabled: Bool = true
    
    // MARK: - Notifications
    var notificationsEnabled: Bool = true
    var collaborationAlerts: Bool = true
    var reminderAlerts: Bool = true
    
    // MARK: - Privacy
    var analyticsEnabled: Bool = true
    var crashReportsEnabled: Bool = true
}

// MARK: - Settings Manager

@Observable
class SettingsManager {
    /// Current user settings
    private(set) var settings: UserSettings
    
    /// Whether settings have unsaved changes
    var isDirty: Bool = false
    
    /// Sync service reference (set after auth)
    weak var syncService: SyncService?
    
    // MARK: - Initialization
    
    init() {
        settings = Self.loadFromDisk() ?? UserSettings()
    }
    
    // MARK: - Update Settings
    
    /// Update settings with a closure
    func update(_ updates: (inout UserSettings) -> Void) {
        updates(&settings)
        settings.updatedAt = Date()
        isDirty = true
        saveToDisk()
        scheduleSync()
    }
    
    // MARK: - Persistence (Local)
    
    private static let storageKey = "com.writa.userSettings"
    
    private static func loadFromDisk() -> UserSettings? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(UserSettings.self, from: data)
    }
    
    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
    
    // MARK: - Cloud Sync (Placeholder)
    
    private var syncTask: Task<Void, Never>?
    
    private func scheduleSync() {
        // Debounce sync calls
        syncTask?.cancel()
        syncTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            await syncToCloud()
        }
    }
    
    /// Sync settings to cloud
    @MainActor
    func syncToCloud() async {
        // TODO: Implement with Clerk + Cloudflare
        // This will be called when:
        // 1. Settings change (debounced)
        // 2. App launches (pull latest)
        // 3. User explicitly triggers sync
        
        guard syncService != nil else {
            print("⚠️ SettingsManager: No sync service configured")
            return
        }
        
        print("☁️ Settings sync triggered (not implemented)")
        isDirty = false
    }
    
    /// Pull settings from cloud
    @MainActor
    func pullFromCloud() async {
        // TODO: Implement pull and merge
        // Conflict resolution:
        // 1. Compare timestamps
        // 2. If cloud is newer, apply cloud settings
        // 3. If local is newer, push to cloud
        
        print("☁️ Settings pull triggered (not implemented)")
    }
    
    /// Merge cloud settings with local
    func merge(cloudSettings: UserSettings) {
        // Simple last-write-wins based on timestamp
        if cloudSettings.updatedAt > settings.updatedAt {
            settings = cloudSettings
            saveToDisk()
            print("☁️ Applied cloud settings (newer)")
        } else {
            print("☁️ Keeping local settings (newer)")
        }
    }
    
    /// Export settings to dictionary for API sync
    func exportToJSON() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        guard let data = try? encoder.encode(settings),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        return dict
    }
    
    /// Shared singleton instance
    static let shared = SettingsManager()
}

// MARK: - Environment Key

private struct SettingsManagerKey: EnvironmentKey {
    static let defaultValue = SettingsManager()
}

extension EnvironmentValues {
    var settingsManager: SettingsManager {
        get { self[SettingsManagerKey.self] }
        set { self[SettingsManagerKey.self] = newValue }
    }
}

// MARK: - Export/Import for Backup

extension UserSettings {
    /// Export settings to JSON string
    func exportToJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Import settings from JSON string
    static func importFromJSON(_ json: String) -> UserSettings? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(UserSettings.self, from: data)
    }
}
