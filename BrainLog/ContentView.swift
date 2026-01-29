//
//  ContentView.swift
//  BrainLog
//
//  Created by 橋本純一 on 2026/01/29.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @State private var showingNewEntry = false
    @State private var selectedItem: Item?
    @State private var branchFromItem: Item?
    @State private var showingHelp = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                if items.isEmpty {
                    emptyStateView
                } else {
                    commitTreeView
                }
            }
            .navigationTitle("BrainLog")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(parentItem: nil)
            }
            .sheet(item: $branchFromItem) { item in
                NewEntryView(parentItem: item)
            }
            .sheet(item: $selectedItem) { item in
                EntryDetailView(item: item, onDelete: { deleteItem(item) })
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "0d1117") : Color(hex: "ffffff")
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No entries yet")
                .font(.headline)
                .foregroundStyle(primaryTextColor)
            Text("Tap + to create your first commit")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { showingHelp = true }) {
                Label("How to use", systemImage: "questionmark.circle")
                    .font(.subheadline)
            }
            .padding(.top, 8)
        }
    }

    private var commitTreeView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(organizedItems.enumerated()), id: \.element.id) { index, item in
                    CommitNodeView(
                        item: item,
                        isFirst: index == 0,
                        isLast: index == organizedItems.count - 1 && !hasBranches(for: item),
                        hasBranch: hasBranches(for: item),
                        branches: getBranches(for: item),
                        onTap: { selectedItem = item },
                        onBranch: { branchFromItem = item },
                        onDelete: { deleteItem(item) }
                    )
                }
            }
            .padding(.vertical)
        }
    }

    private var organizedItems: [Item] {
        items.filter { $0.parentID == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func hasBranches(for item: Item) -> Bool {
        items.contains { $0.parentID == item.id }
    }

    private func getBranches(for item: Item) -> [Item] {
        items.filter { $0.parentID == item.id }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private func deleteItem(_ item: Item) {
        // Also delete all branches of this item
        let branches = items.filter { $0.parentID == item.id }
        for branch in branches {
            modelContext.delete(branch)
        }
        modelContext.delete(item)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

// MARK: - Help View
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        helpSection(
                            icon: "plus.circle.fill",
                            iconColor: .green,
                            title: "Create a Commit",
                            description: "Tap the + button in the top right to create a new entry. Each entry is like a Git commit - a snapshot of your thoughts."
                        )

                        helpSection(
                            icon: "arrow.triangle.branch",
                            iconColor: .purple,
                            title: "Create a Branch",
                            description: "Long press on any commit to create a branch. Branches let you explore related ideas or tangents from a main thought."
                        )

                        helpSection(
                            icon: "hand.tap.fill",
                            iconColor: .blue,
                            title: "View Details",
                            description: "Tap on any commit to view its full content, edit it, or delete it."
                        )

                        helpSection(
                            icon: "trash.fill",
                            iconColor: .red,
                            title: "Delete",
                            description: "Swipe left on a commit to delete it, or use the delete button in the detail view. Deleting a commit also removes its branches."
                        )

                        helpSection(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "iCloud Sync",
                            description: "Your entries are automatically synced across all your devices via iCloud."
                        )

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func helpSection(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "0d1117") : Color(hex: "ffffff")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

// MARK: - Commit Node View
struct CommitNodeView: View {
    let item: Item
    let isFirst: Bool
    let isLast: Bool
    let hasBranch: Bool
    let branches: [Item]
    let onTap: () -> Void
    let onBranch: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let nodeSize: CGFloat = 12
    private let lineWidth: CGFloat = 2

    var body: some View {
        VStack(spacing: 0) {
            mainCommitRow

            if hasBranch {
                ForEach(Array(branches.enumerated()), id: \.element.id) { index, branch in
                    BranchNodeView(
                        item: branch,
                        isLastBranch: index == branches.count - 1,
                        parentHasMore: !isLast,
                        onDelete: {}
                    )
                }
            }
        }
    }

    private var mainCommitRow: some View {
        HStack(alignment: .top, spacing: 16) {
            commitGraphView
            commitContentView
            Spacer()
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(action: onBranch) {
                Label("Create Branch", systemImage: "arrow.triangle.branch")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var commitGraphView: some View {
        ZStack {
            // Line above (connecting to previous commit)
            if !isFirst {
                VStack {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: lineWidth, height: 30)
                    Spacer()
                }
            }

            // Line below (connecting to next commit or branches)
            if !isLast || hasBranch {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: lineWidth, height: 50)
                }
            }

            // The commit node
            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
        }
        .frame(width: 20, height: 80)
    }

    private var commitContentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(primaryTextColor)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(shortHash)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(hashColor)

                Text(relativeDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let branchName = item.branchName {
                    Text(branchName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(branchBadgeColor)
                        .foregroundStyle(branchTextColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 16)
    }

    private var shortHash: String {
        String(item.id.uuidString.prefix(7)).lowercased()
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    private var nodeColor: Color {
        colorScheme == .dark ? Color(hex: "238636") : Color(hex: "1a7f37")
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color(hex: "30363d") : Color(hex: "d0d7de")
    }

    private var hashColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var branchBadgeColor: Color {
        colorScheme == .dark ? Color(hex: "388bfd26") : Color(hex: "ddf4ff")
    }

    private var branchTextColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }
}

// MARK: - Branch Node View
struct BranchNodeView: View {
    let item: Item
    let isLastBranch: Bool
    let parentHasMore: Bool
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: Item?

    private let nodeSize: CGFloat = 10
    private let lineWidth: CGFloat = 2

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            branchGraphView
            branchContentView
                .padding(.leading, 8)
            Spacer()
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture { selectedItem = item }
        .sheet(item: $selectedItem) { item in
            EntryDetailView(item: item, onDelete: { modelContext.delete(item) })
        }
    }

    private var branchGraphView: some View {
        ZStack(alignment: .topLeading) {
            // Vertical line continuing from parent (if parent has more commits below)
            if parentHasMore {
                Rectangle()
                    .fill(lineColor)
                    .frame(width: lineWidth, height: 60)
                    .offset(x: 9)
            }

            // Branch curve
            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 15))
                path.addQuadCurve(
                    to: CGPoint(x: 35, y: 30),
                    control: CGPoint(x: 10, y: 30)
                )
            }
            .stroke(branchLineColor, lineWidth: lineWidth)

            // Branch node
            Circle()
                .fill(branchNodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .offset(x: 30, y: 25)
        }
        .frame(width: 50, height: 60)
    }

    private var branchContentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.content)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(primaryTextColor)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text(shortHash)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(hashColor)

                Text(relativeDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let branchName = item.branchName {
                    Text(branchName)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(branchBadgeColor)
                        .foregroundStyle(branchTextColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var shortHash: String {
        String(item.id.uuidString.prefix(7)).lowercased()
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    private var branchNodeColor: Color {
        colorScheme == .dark ? Color(hex: "a371f7") : Color(hex: "8250df")
    }

    private var branchLineColor: Color {
        colorScheme == .dark ? Color(hex: "6e40c9") : Color(hex: "8250df")
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color(hex: "30363d") : Color(hex: "d0d7de")
    }

    private var hashColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var branchBadgeColor: Color {
        colorScheme == .dark ? Color(hex: "388bfd26") : Color(hex: "ddf4ff")
    }

    private var branchTextColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }
}

// MARK: - New Entry View
struct NewEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let parentItem: Item?

    @State private var content = ""
    @State private var branchName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if parentItem != nil {
                        TextField("Branch name (optional)", text: $branchName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(editorBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: 1)
                        )

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(parentItem == nil ? "New Commit" : "New Branch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Commit") {
                        saveEntry()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveEntry() {
        let newItem = Item(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            parentID: parentItem?.id,
            branchName: branchName.isEmpty ? nil : branchName
        )
        modelContext.insert(newItem)
        dismiss()
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "0d1117") : Color(hex: "ffffff")
    }

    private var editorBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "161b22") : Color(hex: "f6f8fa")
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color(hex: "30363d") : Color(hex: "d0d7de")
    }
}

// MARK: - Entry Detail View
struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var item: Item
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        commitHeader

                        Divider()

                        if isEditing {
                            TextEditor(text: $editedContent)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .background(editorBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text(item.content)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(primaryTextColor)
                        }

                        Spacer(minLength: 40)

                        if !isEditing {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Commit", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Commit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            item.content = editedContent
                            item.updatedAt = Date()
                            isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            editedContent = item.content
                            isEditing = true
                        }
                    }
                }
            }
            .alert("Delete Commit?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This will also delete any branches from this commit. This action cannot be undone.")
            }
        }
    }

    private var commitHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(nodeColor)
                    .frame(width: 10, height: 10)

                Text(item.id.uuidString.prefix(7).lowercased())
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(hashColor)

                if let branchName = item.branchName {
                    Text(branchName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(branchBadgeColor)
                        .foregroundStyle(branchTextColor)
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                Label(formatDate(item.createdAt), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if item.updatedAt != item.createdAt {
                    Label("Updated \(formatDate(item.updatedAt))", systemImage: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "0d1117") : Color(hex: "ffffff")
    }

    private var editorBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "161b22") : Color(hex: "f6f8fa")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var nodeColor: Color {
        colorScheme == .dark ? Color(hex: "238636") : Color(hex: "1a7f37")
    }

    private var hashColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }

    private var branchBadgeColor: Color {
        colorScheme == .dark ? Color(hex: "388bfd26") : Color(hex: "ddf4ff")
    }

    private var branchTextColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
