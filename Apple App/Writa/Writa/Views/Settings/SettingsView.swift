//
//  SettingsView.swift
//  Writa
//
//  Application settings with theme customization.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            EditorSettingsView()
                .tabItem {
                    Label("Editor", systemImage: "pencil")
                }
            
            AccountSettingsView()
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
            
            SyncSettingsView()
                .tabItem {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("defaultFolder") private var defaultFolder = "inbox"
    @AppStorage("showWordCount") private var showWordCount = true
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("autoSaveInterval") private var autoSaveInterval = 30.0
    
    var body: some View {
        Form {
            Section("Documents") {
                Picker("Default Location", selection: $defaultFolder) {
                    Text("Inbox").tag("inbox")
                    Text("Last Used Folder").tag("last")
                }
                .pickerStyle(.menu)
                
                Toggle("Show word count", isOn: $showWordCount)
            }
            
            Section("Auto Save") {
                Toggle("Auto-save documents", isOn: $autoSave)
                
                if autoSave {
                    Picker("Save interval", selection: $autoSaveInterval) {
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                        Text("5 minutes").tag(300.0)
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section("Startup") {
                Toggle("Open last document on launch", isOn: .constant(true))
                Toggle("Restore window positions", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: Binding(
                    get: { themeManager.mode },
                    set: { themeManager.mode = $0 }
                )) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Preset", selection: Binding(
                    get: { themeManager.preset },
                    set: { themeManager.preset = $0 }
                )) {
                    ForEach(ThemePreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("Accent Color") {
                Toggle("Use system accent color", isOn: Binding(
                    get: { themeManager.useSystemAccent },
                    set: { themeManager.useSystemAccent = $0 }
                ))
                
                if !themeManager.useSystemAccent {
                    ColorPicker("Custom accent", selection: Binding(
                        get: { themeManager.customAccentColor },
                        set: { themeManager.customAccentColor = $0 }
                    ))
                }
            }
            
            Section("Sidebar") {
                Toggle("Show document count badges", isOn: .constant(true))
                Toggle("Show sync status", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Editor Settings

struct EditorSettingsView: View {
    @Environment(\.themeManager) private var themeManager
    
    @State private var availableFonts: [String] = {
        NSFontManager.shared.availableFontFamilies.sorted()
    }()
    
    var body: some View {
        Form {
            Section("Typography") {
                Picker("Font", selection: Binding(
                    get: { themeManager.editorFontFamily },
                    set: { themeManager.editorFontFamily = $0 }
                )) {
                    Text("System (SF Pro)").tag(".AppleSystemUIFont")
                    Text("New York (Serif)").tag("New York")
                    Divider()
                    ForEach(availableFonts.prefix(50), id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.menu)
                
                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { themeManager.editorFontSize },
                            set: { themeManager.editorFontSize = $0 }
                        ),
                        in: 12...24,
                        step: 1
                    )
                    .frame(width: 150)
                    Text("\(Int(themeManager.editorFontSize))pt")
                        .monospacedDigit()
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Line Height")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { themeManager.editorLineHeight },
                            set: { themeManager.editorLineHeight = $0 }
                        ),
                        in: 1.2...2.0,
                        step: 0.1
                    )
                    .frame(width: 150)
                    Text(String(format: "%.1f", themeManager.editorLineHeight))
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
            
            Section("Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The quick brown fox jumps over the lazy dog.")
                        .font(.custom(
                            themeManager.editorFontFamily == ".AppleSystemUIFont" ? ".AppleSystemUIFont" : themeManager.editorFontFamily,
                            size: themeManager.editorFontSize
                        ))
                        .lineSpacing(themeManager.editorFontSize * (themeManager.editorLineHeight - 1))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            Section("Editor Behavior") {
                Toggle("Show line numbers", isOn: .constant(false))
                Toggle("Enable spell checking", isOn: .constant(true))
                Toggle("Enable grammar checking", isOn: .constant(true))
                Toggle("Smart quotes", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tertiary)
                    
                    Text("Not signed in")
                        .font(.headline)
                    
                    Text("Sign in to sync your documents across devices and access community content.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    
                    Button("Sign In") {
                        // Sign in action
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Sync Settings

struct SyncSettingsView: View {
    @AppStorage("syncEnabled") private var syncEnabled = true
    @AppStorage("syncOnWifi") private var syncOnWifi = false
    
    var body: some View {
        Form {
            Section("Sync") {
                Toggle("Enable sync", isOn: $syncEnabled)
                Toggle("Sync only on Wi-Fi", isOn: $syncOnWifi)
            }
            
            Section("Status") {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("All documents synced")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Last sync: Just now")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Section("Offline") {
                Toggle("Keep documents available offline", isOn: .constant(true))
                
                HStack {
                    Text("Offline storage used")
                    Spacer()
                    Text("12.4 MB")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button("Sync Now") {
                    // Manual sync
                }
                
                Button("Reset Sync Data", role: .destructive) {
                    // Reset sync
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(\.themeManager, ThemeManager())
}
