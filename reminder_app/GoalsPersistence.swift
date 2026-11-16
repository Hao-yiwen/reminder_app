import Foundation

/// 与主应用一致的 UserDefaults / JSON 编解码（便于单元测试与迁移）
enum GoalsPersistence {
    static let storageKey = "goals"

    private static func makeEncoder() -> JSONEncoder {
        JSONEncoder()
    }

    private static func makeDecoder() -> JSONDecoder {
        JSONDecoder()
    }

    static func decode(from data: Data) throws -> [Goal] {
        try makeDecoder().decode([Goal].self, from: data)
    }

    static func encode(_ goals: [Goal]) throws -> Data {
        try makeEncoder().encode(goals)
    }

    /// 旧版 `try?` 加载逻辑的兼容入口：解码失败时返回空数组并保留原始数据不动
    static func loadReplacingEmptyOnFailure(from data: Data) -> [Goal] {
        (try? decode(from: data)) ?? []
    }
}