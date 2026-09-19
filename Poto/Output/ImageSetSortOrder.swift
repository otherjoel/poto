import Foundation

nonisolated enum ImageSetSortOrder: String, CaseIterable, Identifiable, Sendable {
    case name
    case dateModified

    var id: Self { self }

    var label: String {
        switch self {
        case .name: "Name"
        case .dateModified: "Date Modified"
        }
    }

    func sorted(_ sets: [ImageSet]) -> [ImageSet] {
        switch self {
        case .name:
            sets.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .dateModified:
            sets.sorted { $0.modified > $1.modified }
        }
    }
}
