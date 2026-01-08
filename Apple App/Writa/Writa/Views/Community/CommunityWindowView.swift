//
//  CommunityWindowView.swift
//  Writa
//
//  Community content browser window.
//  Displays public content library for browsing, reading, and importing.
//

import SwiftUI

struct CommunityWindowView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: CommunityCategory = .all
    @State private var selectedContent: CommunityContent?
    
    var body: some View {
        NavigationSplitView {
            // Categories sidebar
            CommunitySidebarView(selection: $selectedCategory)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } content: {
            // Content list
            CommunityContentListView(
                category: selectedCategory,
                searchText: searchText,
                selection: $selectedContent
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            // Content detail
            if let content = selectedContent {
                CommunityContentDetailView(content: content)
            } else {
                CommunityEmptyView()
            }
        }
        .searchable(text: $searchText, prompt: "Search community content")
        .navigationTitle("Community")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Text("Community")
                    .font(.headline)
            }
        }
    }
}

// MARK: - Community Category

enum CommunityCategory: String, CaseIterable, Identifiable {
    case all = "All Content"
    case product = "Product"
    case design = "Design"
    case engineering = "Engineering"
    case strategy = "Strategy"
    case templates = "Templates"
    case frameworks = "Frameworks"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .product: return "cube"
        case .design: return "paintbrush"
        case .engineering: return "gearshape.2"
        case .strategy: return "chart.line.uptrend.xyaxis"
        case .templates: return "doc.text"
        case .frameworks: return "rectangle.3.group"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .secondary
        case .product: return .blue
        case .design: return .purple
        case .engineering: return .orange
        case .strategy: return .green
        case .templates: return .teal
        case .frameworks: return .indigo
        }
    }
}

// MARK: - Community Sidebar

struct CommunitySidebarView: View {
    @Binding var selection: CommunityCategory
    
    var body: some View {
        List(selection: $selection) {
            Section("Browse") {
                ForEach(CommunityCategory.allCases) { category in
                    Label {
                        Text(category.rawValue)
                    } icon: {
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                    }
                    .tag(category)
                }
            }
            
            Section("Collections") {
                Label("Featured", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
                Label("Popular", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                Label("New", systemImage: "sparkles")
                    .foregroundStyle(.blue)
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Community Content Model (Placeholder)

struct CommunityContent: Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String
    let category: CommunityCategory
    let author: String
    let authorAvatar: String?
    let downloadCount: Int
    let rating: Double
    let tags: [String]
    let createdAt: Date
    
    static let samples: [CommunityContent] = [
        CommunityContent(
            id: UUID(),
            title: "Career Ladder Framework",
            summary: "A comprehensive career progression framework for engineering teams with clear levels, expectations, and growth paths.",
            category: .engineering,
            author: "Sarah Chen",
            authorAvatar: nil,
            downloadCount: 2340,
            rating: 4.8,
            tags: ["career", "growth", "levels"],
            createdAt: Date().addingTimeInterval(-86400 * 30)
        ),
        CommunityContent(
            id: UUID(),
            title: "Product Strategy Template",
            summary: "Strategic planning template for product teams including vision, goals, and quarterly objectives.",
            category: .product,
            author: "Mike Johnson",
            authorAvatar: nil,
            downloadCount: 1856,
            rating: 4.6,
            tags: ["strategy", "planning", "okr"],
            createdAt: Date().addingTimeInterval(-86400 * 14)
        ),
        CommunityContent(
            id: UUID(),
            title: "Design System Documentation",
            summary: "Complete design system documentation template with components, tokens, and usage guidelines.",
            category: .design,
            author: "Emily Park",
            authorAvatar: nil,
            downloadCount: 3210,
            rating: 4.9,
            tags: ["design-system", "components", "tokens"],
            createdAt: Date().addingTimeInterval(-86400 * 7)
        )
    ]
}

// MARK: - Community Content List

struct CommunityContentListView: View {
    let category: CommunityCategory
    let searchText: String
    @Binding var selection: CommunityContent?
    
    private var filteredContent: [CommunityContent] {
        var content = CommunityContent.samples
        
        if category != .all {
            content = content.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            content = content.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return content
    }
    
    var body: some View {
        List(filteredContent, selection: $selection) { content in
            CommunityContentRow(content: content)
                .tag(content)
        }
        .listStyle(.inset)
        .navigationTitle(category.rawValue)
    }
}

// MARK: - Community Content Row

struct CommunityContentRow: View {
    let content: CommunityContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category badge
            HStack {
                Label(content.category.rawValue, systemImage: content.category.icon)
                    .font(.caption)
                    .foregroundStyle(content.category.color)
                
                Spacer()
                
                // Rating
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", content.rating))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Title
            Text(content.title)
                .font(.headline)
                .lineLimit(2)
            
            // Summary
            Text(content.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Metadata
            HStack {
                // Author
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.tertiary)
                    Text(content.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Downloads
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.tertiary)
                    Text("\(content.downloadCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Community Content Detail

struct CommunityContentDetailView: View {
    let content: CommunityContent
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    // Category
                    Label(content.category.rawValue, systemImage: content.category.icon)
                        .font(.subheadline)
                        .foregroundStyle(content.category.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(content.category.color.opacity(0.1))
                        .clipShape(Capsule())
                    
                    // Title
                    Text(content.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Summary
                    Text(content.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    // Author & stats
                    HStack(spacing: 16) {
                        // Author
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            VStack(alignment: .leading) {
                                Text(content.author)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Author")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                            .frame(height: 32)
                        
                        // Rating
                        VStack(alignment: .leading) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.1f", content.rating))
                                    .fontWeight(.medium)
                            }
                            Text("Rating")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 32)
                        
                        // Downloads
                        VStack(alignment: .leading) {
                            Text("\(content.downloadCount)")
                                .fontWeight(.medium)
                            Text("Downloads")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Tags
                HStack {
                    ForEach(content.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                }
                
                // Content preview placeholder
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview")
                        .font(.headline)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary)
                        .frame(height: 300)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.richtext")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.tertiary)
                                Text("Content preview will appear here")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                
                Spacer(minLength: 50)
            }
            .padding(32)
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    // Add to library
                } label: {
                    Label("Add to Library", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    // Download
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
            }
        }
    }
}

// MARK: - Community Empty View

struct CommunityEmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Browse Community", systemImage: "globe")
        } description: {
            Text("Select content from the list to preview it.")
        }
    }
}

// MARK: - Preview

#Preview {
    CommunityWindowView()
        .frame(width: 1100, height: 700)
}
