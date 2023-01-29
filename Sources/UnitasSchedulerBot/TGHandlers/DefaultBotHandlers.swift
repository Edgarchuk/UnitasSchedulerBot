
import Vapor
import telegram_vapor_bot

final class DefaultBotHandlers {

    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        Self.api = .init(client: app.client, parser: HTMLParser())
        commandTestHandler(app: app, bot: bot)
        commandSetSemester(app: app, bot: bot)
        buttonActionHandler(app: app, bot: bot)
        commandSetGroup(app: app, bot: bot)
        commandShowScheduler(app: app, bot: bot)
        _ = try? bot.setMyCommands(params: .init(commands: [
            .init(command: "/set_group", description: "Установка группы. Использование: /set_group ПРО-424"),
            .init(command: "/set_semester", description: "Установка семестра. Использование: выбрать семестр из списка"),
            .init(command: "/show", description: "Показывает расписание на семестр"),
            .init(command: "/show_week", description: "Показывает расписание на неделю"),
            .init(command: "/show_today", description: "Показывает сегодняшнее расписание"),
        ]))
    }
    
    private static var api: UnitasApi!

    private static func commandTestHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/test"]) { update, bot in
            try update.message?.reply(text: "ok", bot: bot)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func commandSetGroup(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/set_group"]) { update, bot in
            guard let text = update.message?.text else {
                try update.message?.reply(text: "Error", bot: bot)
                return
            }
            let splitText = text.split(separator: " ")
            if splitText.count == 2 {
                guard let userId = update.message?.from?.id else { fatalError("user id not found") }
                guard let semesterId = api.getSemesterId(key: userId) else {
                    try update.message?.reply(text: "Необходимо установить семестр", bot: bot)
                    return
                }
                let groups = try api.getGroups(for: semesterId)
                let name = splitText.last!.lowercased()
                guard groups.contains(where: {$0.name.lowercased() == name }) else {
                    try update.message?.reply(text: "Группа не найдена", bot: bot)
                    return
                }
                for group in groups {
                    if group.name.lowercased() == name {
                        api.setGroupId(key: userId, value: Int64(group.id))
                        try update.message?.reply(text: "Ок", bot: bot)
                    }
                }
            } else {
                try update.message?.reply(text: "Необходимо передать название группы. Например: /set_group ПРО-424", bot: bot)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func commandSetSemester(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/set_semester"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            let semesters = try api.getSemesters()
            let buttons: [[TGInlineKeyboardButton]] = semesters.map({[TGInlineKeyboardButton(text: "\($0.name)",
                                                                                             callbackData: "semester \(userId) \($0.id)")]})
            let keyboard: TGInlineKeyboardMarkup = .init(inlineKeyboard: buttons)
            let params: TGSendMessageParams = .init(chatId: .chat(userId),
                                                    text: "Выберите семестр",
                                                    replyMarkup: .inlineKeyboardMarkup(keyboard))
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func buttonActionHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCallbackQueryHandler(pattern: "semester \\d+") { update, bot in
            
            guard let tmp = update.callbackQuery?.data?.split(separator: " "), tmp.count == 3,
                  let userId = Int64(tmp[1]), let semesterId = Int64(tmp[2]) else {
                debugPrint("incorrent semester answer")
                return
            }
            api.setSemesterId(key: userId, value: semesterId)
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: "ok",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try bot.answerCallbackQuery(params: params)
        }
        
        bot.connection.dispatcher.add(handler)
    }
    
    private static func commandShowScheduler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/show"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            guard let groupId = api.getGroupId(key: userId), let semesterId = api.getSemesterId(key: userId) else {
                try update.message?.reply(text: "Необходимо установить семестр и группу", bot: bot)
                return
            }
            for day in (try? api.getScheduler(forSemesterId: semesterId, groupId: groupId).withoutNoInfo()) ?? [] {
                try update.message?.reply(text: day.toPrettyString(), bot: bot)
            }
        }
        
        let handlerWeek = TGCommandHandler(commands: ["/show_week"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            guard let groupId = api.getGroupId(key: userId), let semesterId = api.getSemesterId(key: userId) else {
                try update.message?.reply(text: "Необходимо установить семестр и группу", bot: bot)
                return
            }
            for day in (try? api.getSchedulerCurrentWeek(forSemesterId: semesterId, groupId: groupId).withoutNoInfo()) ?? [] {
                try update.message?.reply(text: day.toPrettyString(showWeek: false), bot: bot)
            }
        }
        
        let handlerToday = TGCommandHandler(commands: ["/show_today"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            guard let groupId = api.getGroupId(key: userId), let semesterId = api.getSemesterId(key: userId) else {
                try update.message?.reply(text: "Необходимо установить семестр и группу", bot: bot)
                return
            }
            guard let weekday = Calendar.current.component(.weekday, from: Date()).toRuString() else {
                debugPrint("weekday id is incorrect")
                return
            }
            for day in (try? api.getSchedulerCurrentWeek(forSemesterId: semesterId, groupId: groupId).withoutNoInfo()) ?? [] {
                if day.name == weekday {
                    try update.message?.reply(text: day.toPrettyString(showWeek: false), bot: bot)
                }
            }
        }
        
        bot.connection.dispatcher.add(handler)
        bot.connection.dispatcher.add(handlerWeek)
        bot.connection.dispatcher.add(handlerToday)
    }
}

extension SchedulerDay {
    func toPrettyString(showWeek: Bool = true) -> String {
        var result = "\(self.name)\n"
        for item in self.items {
            result = result + " - \(item.timeRange)\n"
            guard let info = item.info else {
                result = result + " -- Пусто\n"
                continue
            }
            result = result + " -- \(info.subject)\n"
            if showWeek {
                result = result + " --- Недели: \(info.weeks)\n"
            }
            result = result + " --- \(info.lecturer)\n"
            result = result + " --- \(info.type) \(info.audience)\n"
        }
        
        if self.items.count == 0 {
            result = result + " - Пусто\n"
        }
        return result
    }
}

extension Int {
    func toRuString() -> String? {
        let transform =
        [
            1: "Понедельник",
            2: "Вторник",
            3: "Среда",
            4: "Пятница",
            5: "Четверг",
            6: "Суббота"
        ]
        return transform[self]
    }
}
