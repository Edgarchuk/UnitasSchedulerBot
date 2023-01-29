
import Foundation

class FileDataContainer<Key: Codable & Hashable, Value: Codable> {
    
    @Atomic private var data = load() ?? [Key: Value].init()
    
    subscript(key: Key) -> Value? {
        get {
            return data[key]
        }
        set(value) {
            data[key] = value
            try? saveToDisk()
        }
    }
    
    static func load() -> [Key: Value]? {
        let fileURL = Resources.cacheURL
        guard let data = FileManager.default.contents(atPath: fileURL.path) else { return nil }
        do {
            return try JSONDecoder().decode([Key: Value].self, from: data)
        } catch(let error) {
            print(error)
            return nil
        }
    }

    func saveToDisk() throws {

        let fileURL = Resources.cacheURL
        let data = try JSONEncoder().encode(data)
        try data.write(to: fileURL)
    }
}

struct UserData: Codable {
    var groupId: Int64?
    var semesterId: Int64?
}

protocol UserDataContainer {
    func getGroupId(key: Int64) -> Int64?
    func getSemesterId(key: Int64) -> Int64?
    
    func setGroupId(key: Int64, value: Int64?)
    func setSemesterId(key: Int64, value: Int64?)
}


extension FileDataContainer: UserDataContainer where Value == UserData, Key == Int64 {
    func getGroupId(key: Key) -> Int64? {
        return self[key]?.groupId
    }
    
    func getSemesterId(key: Key) -> Int64? {
        return self[key]?.semesterId
    }
    
    func setGroupId(key: Key, value: Int64?) {
        guard var _ = self[key] else {
            self[key] = .init(groupId: value)
            return
        }
        self[key]?.groupId = value
    }
    
    func setSemesterId(key: Key, value: Int64?) {
        guard var _ = self[key] else {
            self[key] = .init(semesterId: value)
            return
        }
        self[key]?.semesterId = value
    }
    
    
}
