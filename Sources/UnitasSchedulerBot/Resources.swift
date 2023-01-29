import Foundation

enum Resources {
    static let cacheFileName = "unitasBot.cache"
    static let cacheURL = { () -> URL in
        let folderURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = folderURLs[0].appendingPathComponent(Resources.cacheFileName)
        return fileURL
    } ()
}
