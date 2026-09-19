import Foundation

nonisolated enum SidebarItem: Hashable, Sendable {
    case queue
    case folder(OutputFolder.ID)
}
