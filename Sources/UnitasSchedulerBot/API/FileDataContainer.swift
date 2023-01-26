
import Foundation

class FileDataContainer<Key: Codable & Hashable, DataType: Codable> {
    
    private var data = [Key: DataType]()
    
    subscript(key: Key) -> DataType? {
        get {
            return data[key]
        }
        set(value) {
            data[key] = value
        }
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


extension FileDataContainer: UserDataContainer where DataType == UserData, Key == Int64 {
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
