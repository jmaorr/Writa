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
            
            ToolbarSettingsView()
                .tabItem {
                    Label("Toolbar", systemImage: "slider.horizontal.3")
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
        .frame(width: 550, height: 500)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("defaultWorkspace") private var defaultWorkspace = "inbox"
    @AppStorage("showWordCount") private var showWordCount = true
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("autoSaveInterval") private var autoSaveInterval = 30.0
    
    var body: some View {
        Form {
            Section("Documents") {
                Picker("Default Location", selection: $defaultWorkspace) {
                    Text("Inbox").tag("inbox")
                    Text("Last Used Workspace").tag("last")
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
    
    // Check if a font family is actually available on the system
    private func isFontFamilyAvailable(_ familyName: String) -> Bool {
        if familyName == ".AppleSystemUIFont" {
            return true // System font is always available
        }
        // Check if the font family exists in available families
        return NSFontManager.shared.availableFontFamilies.contains(familyName)
    }
    
    // Common fonts that might be available (check before showing)
    private var commonFonts: [(name: String, displayName: String)] {
        var fonts: [(name: String, displayName: String)] = []
        
        // System font (always available)
        fonts.append((name: ".AppleSystemUIFont", displayName: "System (SF Pro)"))
        
        // Check for common Apple fonts
        let appleFonts = [
            ("New York", "New York (Serif)"),
            ("SF Mono", "SF Mono (Monospace)"),
            ("Georgia", "Georgia (Serif)"),
            ("Times", "Times (Serif)"),
            ("Helvetica", "Helvetica (Sans)"),
            ("Arial", "Arial (Sans)"),
            ("Courier", "Courier (Monospace)")
        ]
        
        for (fontName, displayName) in appleFonts {
            if isFontFamilyAvailable(fontName) {
                fonts.append((name: fontName, displayName: displayName))
            }
        }
        
        return fonts
    }
    
    var body: some View {
        Form {
            Section("Typography") {
                Picker("Font", selection: Binding(
                    get: { themeManager.editorFontFamily },
                    set: { themeManager.editorFontFamily = $0 }
                )) {
                    // Show only available common fonts
                    ForEach(commonFonts, id: \.name) { font in
                        Text(font.displayName).tag(font.name)
                    }
                    
                    if !commonFonts.isEmpty && !availableFonts.isEmpty {
                        Divider()
                    }
                    
                    // Show other available fonts (limit to first 50)
                    ForEach(availableFonts.filter { font in
                        // Exclude fonts already shown in commonFonts
                        !commonFonts.contains { $0.name == font }
                    }.prefix(50), id: \.self) { font in
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
                        in: 1.0...2.0,
                        step: 0.1
                    )
                    .frame(width: 150)
                    Text(String(format: "%.1f", themeManager.editorLineHeight))
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
            
            Section("Background Colors") {
                HStack {
                    Text("Light Mode")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { themeManager.editorBackgroundColorLight },
                        set: { newColor in
                            // Explicitly set only the light color
                            themeManager.editorBackgroundColorLight = newColor
                        }
                    ))
                    .labelsHidden()
                }
                
                HStack {
                    Text("Dark Mode")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { themeManager.editorBackgroundColorDark },
                        set: { newColor in
                            // Explicitly set only the dark color
                            themeManager.editorBackgroundColorDark = newColor
                        }
                    ))
                    .labelsHidden()
                }
            }
            
            Section("Paragraph Spacing") {
                SpacingRow(label: "Space Before", value: Binding(
                    get: { themeManager.paragraphSpacingBefore },
                    set: { themeManager.paragraphSpacingBefore = $0 }
                ))
                SpacingRow(label: "Space After", value: Binding(
                    get: { themeManager.paragraphSpacingAfter },
                    set: { themeManager.paragraphSpacingAfter = $0 }
                ))
            }
            
            Section("Heading 1 Spacing") {
                SpacingRow(label: "Space Before", value: Binding(
                    get: { themeManager.h1SpacingBefore },
                    set: { themeManager.h1SpacingBefore = $0 }
                ))
                SpacingRow(label: "Space After", value: Binding(
                    get: { themeManager.h1SpacingAfter },
                    set: { themeManager.h1SpacingAfter = $0 }
                ))
            }
            
            Section("Heading 2 Spacing") {
                SpacingRow(label: "Space Before", value: Binding(
                    get: { themeManager.h2SpacingBefore },
                    set: { themeManager.h2SpacingBefore = $0 }
                ))
                SpacingRow(label: "Space After", value: Binding(
                    get: { themeManager.h2SpacingAfter },
                    set: { themeManager.h2SpacingAfter = $0 }
                ))
            }
            
            Section("Heading 3 Spacing") {
                SpacingRow(label: "Space Before", value: Binding(
                    get: { themeManager.h3SpacingBefore },
                    set: { themeManager.h3SpacingBefore = $0 }
                ))
                SpacingRow(label: "Space After", value: Binding(
                    get: { themeManager.h3SpacingAfter },
                    set: { themeManager.h3SpacingAfter = $0 }
                ))
            }
            
            Section("Layout") {
                HStack {
                    Text("Content Width")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { themeManager.editorContentWidth },
                            set: { themeManager.editorContentWidth = $0 }
                        ),
                        in: 500...900,
                        step: 20
                    )
                    .frame(width: 150)
                    Text("\(Int(themeManager.editorContentWidth))px")
                        .monospacedDigit()
                        .frame(width: 50)
                }
                
                HStack {
                    Text("Editor Padding")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { themeManager.editorPadding },
                            set: { themeManager.editorPadding = $0 }
                        ),
                        in: 16...80,
                        step: 4
                    )
                    .frame(width: 150)
                    Text("\(Int(themeManager.editorPadding))px")
                        .monospacedDigit()
                        .frame(width: 50)
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

// MARK: - Toolbar Settings

struct ToolbarSettingsView: View {
    @Environment(\.toolbarConfiguration) private var config
    
    var body: some View {
        Form {
            // My Tools Section
            Section {
                myToolsList
            } header: {
                Text("My Tools")
            } footer: {
                Text("Drag to reorder. Click the × button to remove items. Add separators to create visual groups in your toolbar.")
            }
            
            // Add Separator Button
            Section {
                Button {
                    withAnimation {
                        config.addSeparator()
                    }
                } label: {
                    Label("Add Separator", systemImage: "minus")
                }
            }
            
            // Hidden Tools Section
            Section {
                hiddenToolsList
            } header: {
                Text("Hidden Tools")
            } footer: {
                Text("These tools are available via the + button in the toolbar.")
            }
            
            // Reset
            Section {
                Button("Reset to Defaults") {
                    withAnimation {
                        config.resetToDefaults()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - My Tools List
    
    private var myToolsList: some View {
        List {
            ForEach(Array(config.visibleItems.indices), id: \.self) { index in
                itemRow(config.visibleItems[index], at: index)
            }
            .onMove { source, destination in
                config.moveItem(from: source, to: destination)
            }
            .onDelete { indices in
                for index in indices.sorted().reversed() {
                    config.removeItem(at: index)
                }
            }
        }
        .frame(minHeight: 200)
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func itemRow(_ item: ToolbarEntry, at index: Int) -> some View {
        switch item {
        case .tool(let tool):
            HStack(spacing: 12) {
                // Icon
                Group {
                    if let label = tool.customLabel {
                        Text(label)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    } else {
                        Image(systemName: tool.icon)
                            .font(.system(size: 14))
                    }
                }
                .frame(width: 24)
                .foregroundStyle(.primary)
                
                // Name
                Text(tool.displayName)
                
                Spacer()
                
                // Shortcut
                if let shortcut = tool.shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Remove button
                Button {
                    withAnimation {
                        config.removeItem(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Remove from toolbar")
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            
        case .separator:
            HStack(spacing: 12) {
                Image(systemName: "minus")
                    .font(.system(size: 14))
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                
                Text("Separator")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Visual indicator
                HStack(spacing: 4) {
                    Circle().fill(.quaternary).frame(width: 4, height: 4)
                    Rectangle().fill(.quaternary).frame(width: 20, height: 2)
                    Circle().fill(.quaternary).frame(width: 4, height: 4)
                }
                
                // Remove button
                Button {
                    withAnimation {
                        config.removeItem(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Remove separator")
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - Hidden Tools List
    
    private var hiddenToolsList: some View {
        Group {
            if config.hiddenTools.isEmpty {
                Text("All tools are visible in the toolbar")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(config.hiddenTools) { tool in
                    Button {
                        withAnimation {
                            config.addTool(tool)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Group {
                                if let label = tool.customLabel {
                                    Text(label)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                } else {
                                    Image(systemName: tool.icon)
                                        .font(.system(size: 14))
                                }
                            }
                            .frame(width: 24)
                            
                            Text(tool.displayName)
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Spacing Row Helper

struct SpacingRow: View {
    let label: String
    @Binding var value: CGFloat
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Slider(
                value: $value,
                in: 0...2.0,
                step: 0.1
            )
            .frame(width: 150)
            Text(String(format: "%.1f", value))
                .monospacedDigit()
                .frame(width: 40)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(\.themeManager, ThemeManager())
        .environment(\.toolbarConfiguration, ToolbarConfiguration())
}
