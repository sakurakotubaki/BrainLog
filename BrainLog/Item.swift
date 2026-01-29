import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID = UUID()
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var parentID: UUID?
    var branchName: String?

    init(
        content: String,
        parentID: UUID? = nil,
        branchName: String? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.parentID = parentID
        self.branchName = branchName
    }
}
