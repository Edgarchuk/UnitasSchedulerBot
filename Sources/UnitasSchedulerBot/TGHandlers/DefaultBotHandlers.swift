
import Vapor
import telegram_vapor_bot

final class DefaultBotHandlers {

    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        Self.api = .init(client: app.client, parser: HTMLParser())
        commandTestHandler(app: app, bot: bot)
        commandSetSemester(app: app, bot: bot)
        commandShowButtonsHandler(app: app, bot: bot)
        buttonActionHandler(app: app, bot: bot)
        commandSetGroup(app: app, bot: bot)
        commandShowScheduler(app: app, bot: bot)
    }
    
    private static var api: UnitasApi!
    
    private static func commandStartHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/show_buttons"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            let semesters = try api.getSemesters()
            let buttons: [[TGInlineKeyboardButton]] = semesters.map({[TGInlineKeyboardButton(text: "\($0.name)",
                                                                                             callbackData: "semester \(userId) \($0.id)")]})
            let keyboard: TGInlineKeyboardMarkup = .init(inlineKeyboard: buttons)
            let params: TGSendMessageParams = .init(chatId: .chat(userId),
                                                    text: "Keyboard activ",
                                                    replyMarkup: .inlineKeyboardMarkup(keyboard))
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }

    private static func commandTestHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/test"]) { update, bot in
            try update.message?.reply(text: "ok", bot: bot)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func commandSetSemester(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/semester"]) { update, bot in
            guard let text = update.message?.text else {
                try update.message?.reply(text: "Error", bot: bot)
                return
            }
            let splitText = text.split(separator: " ")
            if splitText.count == 1 {
                var result = ""
                for semester in try api.getSemesters() {
                    result = result + "\(semester.id) - \(semester.name)\n"
                }
                try update.message?.reply(text: result, bot: bot)
            }
            if splitText.count == 2 {
                guard let semesterId = Int64(splitText.last!) else {
                    try update.message?.reply(text: "Нужно передать число!", bot: bot)
                    return
                }
                let semesters = try api.getSemesters()
                if semesters.contains(where: {$0.id == semesterId}) {
                    guard let id = update.message?.from?.id else {
                        try update.message?.reply(text: "Внутренняя ошибка", bot: bot)
                        return
                    }
                    api.setSemesterId(key: id, value: semesterId)
                    try update.message?.reply(text: "ok", bot: bot)
                } else {
                    try update.message?.reply(text: "Неправельный id семестра", bot: bot)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func commandSetGroup(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/group"]) { update, bot in
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
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func commandShowButtonsHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/show_buttons"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            let semesters = try api.getSemesters()
            let buttons: [[TGInlineKeyboardButton]] = semesters.map({[TGInlineKeyboardButton(text: "\($0.name)",
                                                                                             callbackData: "semester \(userId) \($0.id)")]})
            let keyboard: TGInlineKeyboardMarkup = .init(inlineKeyboard: buttons)
            let params: TGSendMessageParams = .init(chatId: .chat(userId),
                                                    text: "Keyboard activ",
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
            for day in (try? api.getScheduler(for: semesterId, and: groupId)) ?? [] {
                var result = "\(day.name)\n"
                for item in day.items {
                    guard let info = item.info else {
                        result = result + "Пусто\n"
                        continue
                    }
                    result = result + "\(info.subject) \(info.lecturer)\n"
                }
                try update.message?.reply(text: result, bot: bot)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
}

