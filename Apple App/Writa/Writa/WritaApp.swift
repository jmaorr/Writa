//
//  WritaApp.swift
//  Writa
//
//  Main application entry point.
//  Defines windows, scenes, and global state.
//

import SwiftUI
import SwiftData
import Clerk

@main
struct WritaApp: App {
    // MARK: - Shared State
    
    @State private var themeManager = ThemeManager()
    @State private var toolbarConfig = ToolbarConfiguration()
    @State private var authManager = AuthManager()
    @State private var syncService: SyncService?
    @State private var documentManager = DocumentManager()
    @State private var autosaveManager = AutosaveManager()
    
    /// Clerk shared instance for environment injection
    @State private var clerk = Clerk.shared
    
    // MARK: - Configuration
    
    /// Clerk publishable key
    /// Get this from: https://dashboard.clerk.com/[your-app]/api-keys
    private let clerkPublishableKey = "pk_test_cHJvYmFibGUtYmF0LTk0LmNsZXJrLmFjY291bnRzLmRldiQ"
    
    // MARK: - Model Container
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Document.self,
            Workspace.self,
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
    
    // Note: syncService is created in onAppear to use the shared authManager

    // MARK: - Body
    
    var body: some Scene {
        // MARK: - Main Window (Personal Library)
        WindowGroup {
            MainContentView()
                .themed(themeManager)
                .toolbarConfiguration(toolbarConfig)
                .environment(\.clerk, clerk)
                .environment(\.authManager, authManager)
                .environment(\.syncService, syncService)
                .environment(\.documentManager, documentManager)
                .environment(\.autosaveManager, autosaveManager)
                .task {
                    // Configure and load Clerk
                    await authManager.configure(publishableKey: clerkPublishableKey)
                }
                .onAppear {
                    // Configure services with model context
                    let context = sharedModelContainer.mainContext
                    documentManager.configure(with: context)
                    autosaveManager.configure(documentManager: documentManager)
                    
                    // Create SyncService with shared authManager
                    if syncService == nil {
                        syncService = SyncService(authManager: authManager)
                    }
                    syncService?.configure(with: documentManager)
                    
                    // Clean up expired trash on app launch
                    documentManager.cleanupExpiredTrash()
                }
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
                .toolbarConfiguration(toolbarConfig)
                .environment(\.clerk, clerk)
                .environment(\.authManager, authManager)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 700)
        .defaultPosition(.center)
        
        // MARK: - Settings Window
        Settings {
            SettingsView()
                .themed(themeManager)
                .toolbarConfiguration(toolbarConfig)
                .environment(\.clerk, clerk)
                .environment(\.authManager, authManager)
                .environment(\.syncService, syncService)
        }
    }
}

// MARK: - Custom Menu Commands

struct WritaCommands: Commands {
    let themeManager: ThemeManager
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        // MARK: - File Menu (Replace default New to prevent New Window)
        CommandGroup(replacing: .newItem) {
            Button("New Document") {
                NotificationCenter.default.post(name: .createNewDocument, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("New Workspace") {
                NotificationCenter.default.post(name: .createNewWorkspace, object: nil)
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
                
                Button("Prompt Snippet") {
                    NotificationCenter.default.post(name: NSNotification.Name("InsertPromptSnippet"), object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
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
            
            Button("Insert Prompt Snippet") {
                // Insert prompt snippet via editor bridge
                NotificationCenter.default.post(name: NSNotification.Name("InsertPromptSnippet"), object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command, .option])
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
