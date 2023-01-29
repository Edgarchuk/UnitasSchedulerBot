
import SwiftSoup
import Foundation

class HTMLParser: ParserProtocol {
    
    fileprivate enum ParseError: Error {
        
        case findText
        case findSchedulerTable
        case findCurrentWeek
    }
    
    func parse(table: Element) throws -> [SchedulerDay] {
        var result: [SchedulerDay] = .init()
        var currentDay: Optional<SchedulerDay> = nil
        
        func saveCurrentDayIfNeeded() {
            if let currentDay = currentDay {
                result.append(currentDay)
            }
        }
        
        for item in try table.select("tbody").select("tr") {
            if try item.checkHave(class: .dayHeader) {
                saveCurrentDayIfNeeded()
                currentDay = .init(items: [], name: try item.getTextInTr(byPosition: .dayName))
            }
            
            let timeRange = try item.getTextInTr(byPosition: .timeRange)
            var info: SchedulerItem.Information? = nil
            
            if !(try item.checkHave(class: .noInfo)) {
                info = .init(
                    weeks: try item.getTextInTr(byPosition: .weeks).split(separator: " ").map({Int($0)!}),
                    subject: try item.getTextInTr(byPosition: .subject),
                    type: try item.getTextInTr(byPosition: .type),
                    lecturer: try item.getTextInTr(byPosition: .lecturer),
                    audience: try item.getTextInTr(byPosition: .audience))
            }
            
            var schedulerItem = SchedulerItem(timeRange: timeRange, info: info)
            currentDay?.items.append(schedulerItem)
        }
        
        saveCurrentDayIfNeeded()
        
        return result
    }
    
    func parseScheduler(input: String) throws -> [SchedulerDay] {
        var result: [SchedulerDay] = .init()
        let doc: Document = try SwiftSoup.parse(input)
        result = try parse(table: try doc.getSchedulerTable())
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
    
    func parseCurrentWeek(input: String) throws -> Int {
        let doc: Document = try SwiftSoup.parse(input)
        guard let text = try doc.getElementsByClass("col-lg-3").first()?.text().split(separator: "№").last,
              let week = Int(text) else {
            throw ParseError.findCurrentWeek
        }
        return week
    }
    
}

extension Element {
    fileprivate enum TableRowClass: String {
        case dayHeader = "dayheader"
        case noInfo = "noinfo"
    }
    
    fileprivate enum DataPositions: Int {
        case dayName = 0
        case timeRange = 1
        case weeks = 2
        case subject = 3
        case type = 4
        case lecturer = 5
        case audience = 6
    }
    
    fileprivate func checkHave(class className: TableRowClass) throws -> Bool {
        return try self.attr("class").split(separator: " ").contains(where: {$0 == className.rawValue})
    }
    
    fileprivate func getSchedulerTable() throws -> Element {
        guard let table = try self.select("table").first() else {
            throw HTMLParser.ParseError.findSchedulerTable
        }
        return table
    }
    
    fileprivate func getTextWeek() throws -> String {
        guard let text = try self.select("p").first()?.text() else {
            throw HTMLParser.ParseError.findText
        }
        return text
    }
    
    fileprivate func getTextInTr(byPosition position: DataPositions) throws -> String {
        guard let text = try self.select("td")[position.rawValue].select("p").first()?.text() else {
            throw HTMLParser.ParseError.findText
        }
        return text
    }
}
 
