import Foundation

struct LaddersResponse: Codable, Sendable {
    let grade: LadderGrade
    let ladders: [Ladder]
}

struct LadderGrade: Codable, Sendable {
    let id: String
    let name: String
    let organisation: LadderOrganisation?
}

struct LadderOrganisation: Codable, Sendable {
    let id: String
    let name: String?
}

struct Ladder: Codable, Sendable, Identifiable {
    var id: String { name }
    let name: String
    let columns: [LadderColumn]
    let pools: [LadderPool]
}

struct LadderColumn: Codable, Sendable, Identifiable {
    let id: String
    let heading: String
    let description: String?
}

struct LadderPool: Codable, Sendable {
    let teams: [TeamStanding]
}

struct TeamStanding: Codable, Sendable, Identifiable {
    let id: String
    let displayName: String
    let owningOrganisation: TeamStandingOrganisation?
    let rank: Int
    let includesAdjustments: Bool?
    let includesUnofficial: Bool?
    let ladderData: [LadderDatum]
}

struct TeamStandingOrganisation: Codable, Sendable {
    let id: String
}

struct LadderDatum: Codable, Sendable, Identifiable {
    let id: String
    let val: LadderValue

    enum CodingKeys: String, CodingKey {
        case id, val
    }
}

enum LadderValue: Codable, Sendable {
    case int(Int)
    case double(Double)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            self = .int(0)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        }
    }

    var displayString: String {
        displayString(forColumn: nil)
    }

    private static let oneDecimalColumns: Set<String> = [
        "oversFaced", "oversBowled"
    ]

    func displayString(forColumn columnId: String?) -> String {
        switch self {
        case .int(let v): return "\(v)"
        case .double(let v):
            if v == v.rounded() && abs(v) < 1_000_000 {
                return "\(Int(v))"
            }
            if let columnId, Self.oneDecimalColumns.contains(columnId) {
                return String(format: "%.1f", v)
            }
            return String(format: "%.3f", v)
        case .string(let v): return v
        }
    }
}
