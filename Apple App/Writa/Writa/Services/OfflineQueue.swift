//
//  OfflineQueue.swift
//  Writa
//
//  Queues failed sync operations for retry when connectivity is restored.
//  Persists operations to disk to survive app restarts.
//

import Foundation
import Network
import Combine

// MARK: - Queued Operation

/// Represents a sync operation that needs to be retried
struct QueuedOperation: Codable, Identifiable {
    let id: UUID
    let type: OperationType
    let entityId: String
    let payload: Data
    let createdAt: Date
    var retryCount: Int
    var lastAttempt: Date?
    var lastError: String?
    
    init(type: OperationType, entityId: String, payload: Data) {
        self.id = UUID()
        self.type = type
        self.entityId = entityId
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
        self.lastAttempt = nil
        self.lastError = nil
    }
}

// MARK: - Operation Type

enum OperationType: String, Codable {
    case createDocument
    case updateDocument
    case deleteDocument
    case createWorkspace
    case updateWorkspace
    case deleteWorkspace
    case updateSettings
    case uploadFile
}

// MARK: - Offline Queue

@Observable
class OfflineQueue {
    /// Shared singleton instance
    static let shared = OfflineQueue()
    
    /// Current queued operations
    private(set) var operations: [QueuedOperation] = []
    
    /// Number of pending operations
    var pendingCount: Int { operations.count }
    
    /// Whether the queue has pending operations
    var hasPendingOperations: Bool { !operations.isEmpty }
    
    /// Current network status
    private(set) var isOnline: Bool = true
    
    /// Whether we're currently processing the queue
    private(set) var isProcessing: Bool = false
    
    /// API client for retrying operations
    private var apiClient: APIClient?
    
    /// Network monitor
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.writa.networkMonitor")
    
    /// Storage key for persistence
    private let storageKey = "com.writa.offlineQueue"
    
    /// Maximum retry attempts before giving up
    private let maxRetries = 5
    
    /// Minimum delay between retries (exponential backoff)
    private let baseRetryDelay: TimeInterval = 5
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadFromDisk()
        startNetworkMonitoring()
    }
    
    /// Configure with API client
    func configure(with apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Queue Operations
    
    /// Add an operation to the queue
    func enqueue(_ operation: QueuedOperation) {
        operations.append(operation)
        saveToDisk()
        print("📥 Queued operation: \(operation.type.rawValue) for \(operation.entityId)")
    }
    
    /// Create and queue a document sync operation
    func queueDocumentSync(id: String, payload: Data, isNew: Bool) {
        let type: OperationType = isNew ? .createDocument : .updateDocument
        let operation = QueuedOperation(type: type, entityId: id, payload: payload)
        enqueue(operation)
    }
    
    /// Create and queue a document delete operation
    func queueDocumentDelete(id: String) {
        let operation = QueuedOperation(type: .deleteDocument, entityId: id, payload: Data())
        enqueue(operation)
    }
    
    /// Create and queue a workspace sync operation
    func queueWorkspaceSync(id: String, payload: Data, isNew: Bool) {
        let type: OperationType = isNew ? .createWorkspace : .updateWorkspace
        let operation = QueuedOperation(type: type, entityId: id, payload: payload)
        enqueue(operation)
    }
    
    /// Create and queue a settings sync operation
    func queueSettingsSync(payload: Data) {
        // Remove any existing settings operation (only keep latest)
        operations.removeAll { $0.type == .updateSettings }
        let operation = QueuedOperation(type: .updateSettings, entityId: "settings", payload: payload)
        enqueue(operation)
    }
    
    /// Remove an operation from the queue
    func remove(_ operation: QueuedOperation) {
        operations.removeAll { $0.id == operation.id }
        saveToDisk()
    }
    
    /// Clear all operations
    func clearAll() {
        operations.removeAll()
        saveToDisk()
        print("🗑️ Cleared offline queue")
    }
    
    // MARK: - Processing
    
    /// Process all queued operations
    func processQueue() async {
        guard !isProcessing else { return }
        guard isOnline else {
            print("⏸️ Offline - skipping queue processing")
            return
        }
        guard let apiClient = apiClient else {
            print("⚠️ OfflineQueue: No API client configured")
            return
        }
        
        isProcessing = true
        print("🔄 Processing offline queue (\(operations.count) operations)")
        
        var successCount = 0
        var failCount = 0
        
        for var operation in operations {
            // Skip if max retries exceeded
            if operation.retryCount >= maxRetries {
                print("❌ Max retries exceeded for \(operation.type.rawValue): \(operation.entityId)")
                remove(operation)
                failCount += 1
                continue
            }
            
            // Calculate exponential backoff
            if let lastAttempt = operation.lastAttempt {
                let delay = baseRetryDelay * pow(2, Double(operation.retryCount))
                let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
                if timeSinceLastAttempt < delay {
                    continue // Not enough time has passed
                }
            }
            
            do {
                try await processOperation(operation, apiClient: apiClient)
                remove(operation)
                successCount += 1
                print("✅ Processed: \(operation.type.rawValue) for \(operation.entityId)")
            } catch {
                operation.retryCount += 1
                operation.lastAttempt = Date()
                operation.lastError = error.localizedDescription
                
                // Update in list
                if let index = operations.firstIndex(where: { $0.id == operation.id }) {
                    operations[index] = operation
                }
                
                failCount += 1
                print("❌ Failed: \(operation.type.rawValue) - \(error.localizedDescription)")
            }
        }
        
        saveToDisk()
        isProcessing = false
        
        print("📊 Queue processing complete: \(successCount) succeeded, \(failCount) failed, \(operations.count) remaining")
    }
    
    /// Process a single operation
    private func processOperation(_ operation: QueuedOperation, apiClient: APIClient) async throws {
        switch operation.type {
        case .createDocument:
            let _: OfflineDocumentResponse = try await apiClient.post("/documents", body: operation.payload)
            
        case .updateDocument:
            let _: OfflineDocumentResponse = try await apiClient.put("/documents/\(operation.entityId)", body: operation.payload)
            
        case .deleteDocument:
            try await apiClient.delete("/documents/\(operation.entityId)")
            
        case .createWorkspace:
            let _: OfflineWorkspaceResponse = try await apiClient.post("/workspaces", body: operation.payload)
            
        case .updateWorkspace:
            let _: OfflineWorkspaceResponse = try await apiClient.put("/workspaces/\(operation.entityId)", body: operation.payload)
            
        case .deleteWorkspace:
            try await apiClient.delete("/workspaces/\(operation.entityId)")
            
        case .updateSettings:
            let _: OfflineSettingsResponse = try await apiClient.put("/settings", body: operation.payload)
            
        case .uploadFile:
            // File uploads need special handling
            // TODO: Implement file upload retry
            break
        }
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOffline = !(self?.isOnline ?? true)
                self?.isOnline = path.status == .satisfied
                
                // Process queue when coming back online
                if wasOffline && (self?.isOnline ?? false) {
                    print("🌐 Network restored - processing queue")
                    Task {
                        await self?.processQueue()
                    }
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        do {
            operations = try JSONDecoder().decode([QueuedOperation].self, from: data)
            print("📂 Loaded \(operations.count) operations from disk")
        } catch {
            print("❌ Failed to load offline queue: \(error)")
        }
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(operations)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save offline queue: \(error)")
        }
    }
}

// MARK: - Response types used for decoding

private struct OfflineDocumentResponse: Codable {
    let success: Bool
}

private struct OfflineWorkspaceResponse: Codable {
    let success: Bool
}

private struct OfflineSettingsResponse: Codable {
    let success: Bool
}
