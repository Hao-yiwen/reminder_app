import XCTest
@testable import GoalModel

final class GoalPersistenceTests: XCTestCase {
    func testDecodeModernPayloadWithUUID() throws {
        let id = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!
        let created = Date(timeIntervalSinceReferenceDate: 700_000_000)
        let checkIn = Date(timeIntervalSinceReferenceDate: 700_086_400)

        let goal = Goal(title: "跑步", checkInDates: [checkIn], created: created, id: id)
        let data = try GoalsPersistence.encode([goal])
        let decoded = try GoalsPersistence.decode(from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].id, id)
        XCTAssertEqual(decoded[0].title, "跑步")
        XCTAssertTrue(decoded[0].checkInDates.contains(checkIn))
        XCTAssertEqual(decoded[0].created, created)
    }

    func testDecodeLegacyJSONWithoutIdField() throws {
        let created = 700_000_000.0
        let checkIn = 700_086_400.0
        let json = """
        [
          {
            "title": "阅读",
            "checkInDates": [\(checkIn)],
            "created": \(created)
          }
        ]
        """.data(using: .utf8)!

        let decoded = try GoalsPersistence.decode(from: json)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].title, "阅读")
        XCTAssertEqual(decoded[0].checkInDates.count, 1)
    }

    func testRoundTripEmptyGoalsArray() throws {
        let data = try GoalsPersistence.encode([])
        let decoded = try GoalsPersistence.decode(from: data)
        XCTAssertTrue(decoded.isEmpty)
    }

    func testInvalidJSONReturnsEmptyFromFallback() {
        let garbage = Data("{not valid".utf8)
        let result = GoalsPersistence.loadReplacingEmptyOnFailure(from: garbage)
        XCTAssertTrue(result.isEmpty)
    }
}