import Foundation

/// 目标数据模型（UserDefaults JSON 持久化）
struct Goal: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var checkInDates: Set<Date>
    var created: Date

    init(title: String, checkInDates: Set<Date> = [], created: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.title = title
        self.checkInDates = checkInDates
        self.created = created
    }

    enum CodingKeys: String, CodingKey {
        case id, title, checkInDates, created
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 兼容旧版存档：早期若 JSON 中缺少 id，不再导致整包解码失败
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        checkInDates = try container.decode(Set<Date>.self, forKey: .checkInDates)
        created = try container.decode(Date.self, forKey: .created)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(checkInDates, forKey: .checkInDates)
        try container.encode(created, forKey: .created)
    }

    var consecutiveStreak: Int {
        var count = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = today

        while checkInDates.contains(calendar.startOfDay(for: currentDate)) {
            count += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return count
    }
}