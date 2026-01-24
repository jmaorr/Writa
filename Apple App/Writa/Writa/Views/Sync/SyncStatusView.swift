//
//  SyncStatusView.swift
//  Writa
//
//  Displays sync status indicator and provides sync controls.
//  Can be used in toolbar, status bar, or as standalone view.
//

import SwiftUI

// MARK: - Sync Status Indicator

/// Compact sync status indicator for toolbar/status bar
struct SyncStatusIndicator: View {
    @Environment(\.syncService) private var syncService
    @Environment(\.authManager) private var authManager
    
    @State private var showingDetails = false
    
    var body: some View {
        Button {
            if authManager.isAuthenticated {
                showingDetails = true
            }
        } label: {
            HStack(spacing: 4) {
                statusIcon
                    .font(.system(size: 12))
                
                if case .syncing = syncService?.syncStatus {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            .foregroundStyle(statusColor)
        }
        .buttonStyle(.plain)
        .help(statusTooltip)
        .popover(isPresented: $showingDetails) {
            SyncStatusPopover()
                .frame(width: 280)
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch syncService?.syncStatus {
            case .idle:
                Image(systemName: "cloud")
            case .syncing:
                Image(systemName: "arrow.triangle.2.circlepath")
            case .success:
                Image(systemName: "checkmark.icloud")
            case .error:
                Image(systemName: "exclamationmark.icloud")
            case .none:
                Image(systemName: "icloud.slash")
            }
        }
    }
    
    private var statusColor: Color {
        guard authManager.isAuthenticated else {
            return .secondary
        }
        
        switch syncService?.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        case .none:
            return .secondary
        }
    }
    
    private var statusTooltip: String {
        guard authManager.isAuthenticated else {
            return "Sign in to enable sync"
        }
        
        switch syncService?.syncStatus {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .success(let date):
            return "Synced \(date.formatted(.relative(presentation: .named)))"
        case .error(let message):
            return "Sync error: \(message)"
        case .none:
            return "Sync unavailable"
        }
    }
}

// MARK: - Sync Status Popover

/// Detailed sync status popover
struct SyncStatusPopover: View {
    @Environment(\.syncService) private var syncService
    @Environment(\.authManager) private var authManager
    
    private let offlineQueue = OfflineQueue.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(.blue)
                Text("Sync Status")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // Status info
            VStack(alignment: .leading, spacing: 12) {
                // Current status
                HStack {
                    Text("Status:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    statusBadge
                }
                
                // Last sync
                if let lastSync = syncService?.lastSyncDate {
                    HStack {
                        Text("Last sync:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(lastSync.formatted(.relative(presentation: .named)))
                    }
                }
                
                // Pending operations
                if offlineQueue.hasPendingOperations {
                    HStack {
                        Text("Pending:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(offlineQueue.pendingCount) operations")
                            .foregroundStyle(.orange)
                    }
                }
                
                // Network status
                HStack {
                    Text("Network:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(offlineQueue.isOnline ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(offlineQueue.isOnline ? "Online" : "Offline")
                    }
                }
            }
            .font(.subheadline)
            
            Divider()
            
            // Actions
            HStack {
                Button("Sync Now") {
                    Task {
                        await syncService?.sync()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(syncService?.isSyncing == true || !authManager.isAuthenticated)
                
                Spacer()
                
                if offlineQueue.hasPendingOperations {
                    Button("Process Queue") {
                        Task {
                            await offlineQueue.processQueue()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
    }
    
    private var statusBadge: some View {
        Group {
            switch syncService?.syncStatus {
            case .idle:
                Label("Ready", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            case .syncing:
                Label("Syncing", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
            case .success:
                Label("Synced", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .error:
                Label("Error", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            case .none:
                Label("Unavailable", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Sync Status Banner

/// Full-width banner for showing sync errors
struct SyncStatusBanner: View {
    @Environment(\.syncService) private var syncService
    
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if isVisible, case .error(let message) = syncService?.syncStatus {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    
                    Text("Sync error: \(message)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button("Retry") {
                        Task {
                            await syncService?.sync()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button {
                        withAnimation {
                            isVisible = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.red.opacity(0.1))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: syncService?.syncStatus) { oldValue, newValue in
            if case .error = newValue {
                withAnimation {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Sync Indicator") {
    SyncStatusIndicator()
        .padding()
}

#Preview("Sync Popover") {
    SyncStatusPopover()
        .frame(width: 280)
}
