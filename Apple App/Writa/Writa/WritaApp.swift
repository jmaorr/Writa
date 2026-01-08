//
//  WritaApp.swift
//  Writa
//
//  Main application entry point.
//  Defines windows, scenes, and global state.
//

import SwiftUI
import SwiftData

@main
struct WritaApp: App {
    // MARK: - Shared State
    
    @State private var themeManager = ThemeManager()
    
    // MARK: - Model Container
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Document.self,
            Folder.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body
    
    var body: some Scene {
        // MARK: - Main Window (Personal Library)
        WindowGroup {
            MainContentView()
                .themed(themeManager)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Custom menu commands
            WritaCommands(themeManager: themeManager)
        }
        
        // MARK: - Community Window
        Window("Community", id: "community") {
            CommunityWindowView()
                .themed(themeManager)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 700)
        .defaultPosition(.center)
        
        // MARK: - Settings Window
        Settings {
            SettingsView()
                .themed(themeManager)
        }
    }
}

// MARK: - Custom Menu Commands

struct WritaCommands: Commands {
    let themeManager: ThemeManager
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        // MARK: - File Menu
        CommandGroup(after: .newItem) {
            Button("New Document") {
                // Will be handled by focused scene
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Divider()
            
            Button("New Folder") {
                // Will be handled by focused scene
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
        
        // MARK: - View Menu Additions
        CommandGroup(after: .sidebar) {
            Divider()
            
            Button("Open Community") {
                openWindow(id: "community")
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
        }
        
        // MARK: - Format Menu (for editor commands)
        CommandMenu("Format") {
            Section {
                Button("Bold") {
                    // Editor command via bridge
                }
                .keyboardShortcut("b", modifiers: .command)
                
                Button("Italic") {
                    // Editor command via bridge
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Button("Underline") {
                    // Editor command via bridge
                }
                .keyboardShortcut("u", modifiers: .command)
                
                Button("Strikethrough") {
                    // Editor command via bridge
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            Divider()
            
            Section {
                Menu("Heading") {
                    Button("Heading 1") {
                        // Editor command
                    }
                    .keyboardShortcut("1", modifiers: [.command, .option])
                    
                    Button("Heading 2") {
                        // Editor command
                    }
                    .keyboardShortcut("2", modifiers: [.command, .option])
                    
                    Button("Heading 3") {
                        // Editor command
                    }
                    .keyboardShortcut("3", modifiers: [.command, .option])
                    
                    Divider()
                    
                    Button("Paragraph") {
                        // Editor command
                    }
                    .keyboardShortcut("0", modifiers: [.command, .option])
                }
            }
            
            Divider()
            
            Section {
                Button("Bullet List") {
                    // Editor command
                }
                .keyboardShortcut("8", modifiers: [.command, .shift])
                
                Button("Numbered List") {
                    // Editor command
                }
                .keyboardShortcut("7", modifiers: [.command, .shift])
                
                Button("Checklist") {
                    // Editor command
                }
                .keyboardShortcut("9", modifiers: [.command, .shift])
            }
            
            Divider()
            
            Section {
                Button("Quote") {
                    // Editor command
                }
                .keyboardShortcut("'", modifiers: .command)
                
                Button("Code Block") {
                    // Editor command
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
                
                Button("Callout") {
                    // Editor command
                }
            }
        }
        
        // MARK: - Insert Menu
        CommandMenu("Insert") {
            Button("Image...") {
                // Open image picker
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            
            Button("Link...") {
                // Open link dialog
            }
            .keyboardShortcut("k", modifiers: .command)
            
            Divider()
            
            Button("Horizontal Rule") {
                // Insert hr
            }
            
            Button("Table...") {
                // Insert table
            }
            
            Divider()
            
            Menu("Prompt Snippet") {
                Button("Insert Snippet...") {
                    // Open snippet picker
                }
                
                Button("Browse Snippets...") {
                    // Open snippet library
                }
            }
        }
        
        // MARK: - Help Menu
        CommandGroup(replacing: .help) {
            Button("Writa Help") {
                // Open help
            }
            
            Divider()
            
            Button("Keyboard Shortcuts") {
                // Show shortcuts
            }
            .keyboardShortcut("/", modifiers: .command)
            
            Button("What's New") {
                // Show what's new
            }
            
            Divider()
            
            Button("Send Feedback...") {
                // Open feedback
            }
        }
    }
}
