import Foundation

struct SchedulerItem {
    let timeRange: String
    let info: Optional<Information>
    
    struct Information {
        let weeks: [Int]
        let subject: String
        let type: String
        let lecturer: String
        let audience: String
    }
}

struct SchedulerDay {
    var items: [SchedulerItem]
    var name: String
}

struct Group {
    var id: Int
    var name: String
}

struct Semester: Identifiable, Hashable {
    var id: Int
    var name: String
}

protocol ParserProtocol {
    func parseScheduler(input: String) throws -> [SchedulerDay]
    func parseGroups(input: String) throws -> [Group]
    func parseSemesters(input: String) throws -> [Semester]
}
