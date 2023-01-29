import Foundation
import Vapor

class UnitasApi: UserDataContainer {
    
    static let url: URI = "https://isu.ugatu.su/api/new_schedule_api/"
    
    private var client: Client
    private var parser: ParserProtocol
    private var userData: UserDataContainer = FileDataContainer<Int64, UserData>()
    
    init(client: Client, parser: ParserProtocol) {
        self.client = client
        self.parser = parser
    }
    
    enum Parameters {
        case startPage
        case group(scheduleSemesterId: Int, studentGroupId: Optional<Int>)
        
        func toRawValues() -> Dictionary<String, String> {
            var result = Dictionary<String, String>()
            switch self {
            case .startPage:
                break
            case .group(let scheduleSemesterId, let studentGroupId):
                result["schedule_semestr_id"] = String(scheduleSemesterId)
                result["WhatShow"] = "1"
                if let studentGroupId = studentGroupId {
                    result["student_group_id"] = String(studentGroupId)
                }
                break
            }
            return result
        }
    }
    
    func getGroupId(key: Int64) -> Int64? {
        return userData.getGroupId(key: key)
    }
    
    func getSemesterId(key: Int64) -> Int64? {
        return userData.getSemesterId(key: key)
    }
    
    func setGroupId(key: Int64, value: Int64?) {
        return userData.setGroupId(key: key, value: value)
    }
    
    func setSemesterId(key: Int64, value: Int64?) {
        return userData.setSemesterId(key: key, value: value)
    }
    
    private func getHtml(withParameters parameters: Parameters) throws -> String {
        var uri = UnitasApi.url
        uri.query = createQuery(with: parameters)
        let future = client.get(uri)
        let response = try future.wait()
        print(response.status)
        if response.status == .ok {
            if var body = response.body,
               let bodyBites = body.readBytes(length: body.readableBytes),
               let result = String(bytes: bodyBites, encoding: .utf8) {
                return result
            }
        }
        return ""
    }
    
    private func createQuery(with parameters: Parameters) -> String {
        var components = URLComponents()
        components.queryItems = parameters.toRawValues().map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        return components.percentEncodedQuery!
    }
    func getSemesters() throws -> [Semester] {
        let html = try getHtml(withParameters: .startPage)
        return try parser.parseSemesters(input: html)
    }
    
    func getGroups(for semesterId: Int64) throws -> [Group] {
        let html = try getHtml(withParameters: .group(scheduleSemesterId: Int(semesterId), studentGroupId: nil))
        return try parser.parseGroups(input: html)
    }
    
    func getScheduler(forSemesterId semesterId: Int64, groupId: Int64) throws -> [SchedulerDay] {
        let html = try getHtml(withParameters: .group(scheduleSemesterId: Int(semesterId), studentGroupId: Int(groupId)))
        return try parser.parseScheduler(input: html)
    }
    
    func getSchedulerCurrentWeek(forSemesterId semesterId: Int64, groupId: Int64) throws -> [SchedulerDay] {
        let html = try getHtml(withParameters: .group(scheduleSemesterId: Int(semesterId), studentGroupId: Int(groupId)))
        let week = try parser.parseCurrentWeek(input: html)
        let days = try parser.parseScheduler(input: html).map({SchedulerDay(items: $0.items.filter({ item in
            guard let info = item.info else {
                return true
            }
            return info.weeks.contains(where: {$0 == week})
        }), name: $0.name)})
        return days
    }
}

extension Dictionary {
    func toArray() -> [(Key, Value)] {
        var result = [(Key, Value)]()
        for (key, value) in self {
            result.append((key, value))
        }
        return result
    }
}

extension Array where Element == SchedulerDay {
    func withoutNoInfo() -> Self {
        return self.map({SchedulerDay(items: $0.items.filter({$0.info != nil}), name: $0.name)})
    }
}
