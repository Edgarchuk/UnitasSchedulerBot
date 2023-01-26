
import Foundation
import Vapor
import telegram_vapor_bot

public func configure(_ app: Application) throws {
    guard let tgApi: String = ProcessInfo.processInfo.environment["UNITAS_BOT_TOKEN"] else {
        fatalError("set UNITAS_BOT_TOKEN")
    }
    let connection: TGConnectionPrtcl = TGLongPollingConnection()
    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
    try TGBot.shared.start()
    TGBot.log.logLevel = .trace
    DefaultBotHandlers.addHandlers(app: app, bot: TGBot.shared)

    try routes(app)
}
