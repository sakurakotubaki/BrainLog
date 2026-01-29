import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @State private var showingNewEntry = false
    @State private var selectedItem: Item?
    @State private var reflectionFromItem: Item?
    @State private var showingHelp = false
    @State private var languageManager = LanguageManager.shared

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
            .navigationTitle("app_title".localized())
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
            .sheet(item: $reflectionFromItem) { item in
                NewReflectionView(parentItem: item)
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
            Text("no_entries_title".localized())
                .font(.headline)
                .foregroundStyle(primaryTextColor)
            Text("no_entries_subtitle".localized())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { showingHelp = true }) {
                Label("help_title".localized(), systemImage: "questionmark.circle")
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
                        onReflection: { reflectionFromItem = item },
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
                            title: "help_create_title".localized(),
                            description: "help_create_description".localized()
                        )

                        helpSection(
                            icon: "bubble.left.and.text.bubble.right.fill",
                            iconColor: .purple,
                            title: "help_reflection_title".localized(),
                            description: "help_reflection_description".localized()
                        )

                        helpSection(
                            icon: "hand.tap.fill",
                            iconColor: .blue,
                            title: "help_view_title".localized(),
                            description: "help_view_description".localized()
                        )

                        helpSection(
                            icon: "trash.fill",
                            iconColor: .red,
                            title: "help_delete_title".localized(),
                            description: "help_delete_description".localized()
                        )

                        helpSection(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "help_sync_title".localized(),
                            description: "help_sync_description".localized()
                        )

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("help_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_done".localized()) { dismiss() }
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
    let onReflection: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let nodeSize: CGFloat = 12
    private let lineWidth: CGFloat = 2

    var body: some View {
        VStack(spacing: 0) {
            mainCommitRow

            if hasBranch {
                ForEach(Array(branches.enumerated()), id: \.element.id) { index, reflection in
                    ReflectionNodeView(
                        item: reflection,
                        isLastReflection: index == branches.count - 1,
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
            Button(action: onReflection) {
                Label("action_add_reflection".localized(), systemImage: "bubble.left.and.text.bubble.right")
            }
            Button(role: .destructive, action: onDelete) {
                Label("action_delete".localized(), systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("action_delete".localized(), systemImage: "trash")
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

// MARK: - Reflection Node View
struct ReflectionNodeView: View {
    let item: Item
    let isLastReflection: Bool
    let parentHasMore: Bool
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: Item?

    private let nodeSize: CGFloat = 10
    private let lineWidth: CGFloat = 2

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            reflectionGraphView
            reflectionContentView
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

    private var reflectionGraphView: some View {
        ZStack(alignment: .topLeading) {
            // Vertical line continuing from parent (if parent has more commits below)
            if parentHasMore {
                Rectangle()
                    .fill(lineColor)
                    .frame(width: lineWidth, height: 60)
                    .offset(x: 9)
            }

            // Reflection curve
            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 15))
                path.addQuadCurve(
                    to: CGPoint(x: 35, y: 30),
                    control: CGPoint(x: 10, y: 30)
                )
            }
            .stroke(reflectionLineColor, lineWidth: lineWidth)

            // Reflection icon
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 12))
                .foregroundStyle(reflectionNodeColor)
                .offset(x: 26, y: 22)
        }
        .frame(width: 50, height: 60)
    }

    private var reflectionContentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("reflection_label".localized())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(reflectionNodeColor)
            }

            Text(item.content)
                .font(.system(.subheadline, design: .default))
                .italic()
                .foregroundStyle(primaryTextColor)
                .lineLimit(2)

            Text(relativeDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    private var reflectionNodeColor: Color {
        colorScheme == .dark ? Color(hex: "a371f7") : Color(hex: "8250df")
    }

    private var reflectionLineColor: Color {
        colorScheme == .dark ? Color(hex: "6e40c9") : Color(hex: "8250df")
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color(hex: "30363d") : Color(hex: "d0d7de")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

// MARK: - New Entry View
struct NewEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let parentItem: Item?

    @State private var content = ""

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
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
            .navigationTitle("new_entry_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel".localized()) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_save".localized()) {
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
            parentID: nil,
            branchName: nil
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

// MARK: - New Reflection View
struct NewReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let parentItem: Item

    @State private var content = ""

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    // Original entry preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("reflecting_on".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(parentItem.content)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(primaryTextColor)
                            .lineLimit(3)
                            .padding()
                            .background(editorBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Text("your_reflection".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $content)
                        .font(.system(.body, design: .default))
                        .scrollContentBackground(.hidden)
                        .background(editorBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(reflectionColor.opacity(0.5), lineWidth: 1)
                        )

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("new_reflection_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel".localized()) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_save".localized()) {
                        saveReflection()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveReflection() {
        let newItem = Item(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            parentID: parentItem.id,
            branchName: nil
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

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var reflectionColor: Color {
        colorScheme == .dark ? Color(hex: "a371f7") : Color(hex: "8250df")
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
                                Label("delete_entry_button".localized(), systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("entry_detail_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_close".localized()) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("action_save".localized()) {
                            item.content = editedContent
                            item.updatedAt = Date()
                            isEditing = false
                        }
                    } else {
                        Button("action_edit".localized()) {
                            editedContent = item.content
                            isEditing = true
                        }
                    }
                }
            }
            .alert("delete_entry_alert_title".localized(), isPresented: $showDeleteConfirmation) {
                Button("action_cancel".localized(), role: .cancel) {}
                Button("action_delete".localized(), role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("delete_entry_alert_message".localized())
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
