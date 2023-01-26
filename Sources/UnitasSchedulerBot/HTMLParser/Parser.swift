
import SwiftSoup
import Foundation

class StringParser: ParserProtocol {
    
    enum ParseError: Error {
        
        case errorInFindText
    }
    
    func parse(table: Element) throws -> [SchedulerDay] {
        var result: [SchedulerDay] = .init()
        var currentDay: Optional<SchedulerDay> = nil
        for item in try table.select("tr") {
            let tds = try item.select("td")
            if tds.count == 1 {
                let text = try tds.first()!.text()
                if let currentDay = currentDay {
                    result.append(currentDay)
                }
                currentDay = .init(items: [], name: text)
            }
            if tds.count == 2 {
                let time = try tds.first()!.getTextFormTd()
                currentDay?.items.append(.init(timeRange: time, info: nil))
            }
            if tds.count > 2 {
                let time = try tds.first()!.getTextFormTd()
                let weeks = try tds[1].getTextFormTd().split(separator: " ").map({Int($0)!})
                let subject = try tds[2].getTextFormTd()
                let type = try tds[3].getTextFormTd()
                let lecturer = try tds[4].getTextFormTd()
                let audience = try tds[5].getTextFormTd()
                currentDay?.items.append(.init(
                    timeRange: time, info: .init(weeks: weeks, subject: subject, type: type, lecturer: lecturer, audience: audience)
                ))
            }
        }
        
        if let currentDay = currentDay {
            result.append(currentDay)
        }
        
        return result
    }
    
    func parseScheduler(input: String) throws -> [SchedulerDay] {
        var result: [SchedulerDay] = .init()
        let doc: Document = try SwiftSoup.parse(input)
        let table = try doc.select("tbody").first()
        if let table = table {
            result = try parse(table: table)
        }
        return result
    }
    
    private func parseSelect<Result>(input: String, name: String, initResult: (Element) throws -> Result) throws -> [Result] {
        var result: [Result] = .init()
        let doc: Document = try SwiftSoup.parse(input)
        let select = try doc.select("select[name=\(name)]")
        for item in try select.select("option") {
            result.append(try initResult(item))
        }
        return result
    }
    
    func parseGroups(input: String) throws -> [Group] {
        return try parseSelect(input: input, name: "student_group_id", initResult: {
            .init(id: Int(try $0.val())!, name: try $0.text())
        })
    }
    
    func parseSemesters(input: String) throws -> [Semester] {
        return try parseSelect(input: input, name: "schedule_semestr_id", initResult: {
            .init(id: Int(try $0.val())!, name: try $0.text())
        })
    }
    
}

extension Element {
    fileprivate func getTextFormTd() throws -> String {
        guard let text = try self.select("p").first()?.text() else {
            throw StringParser.ParseError.errorInFindText
        }
        return text
    }
}
