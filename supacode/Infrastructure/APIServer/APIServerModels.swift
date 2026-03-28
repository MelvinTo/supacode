import Foundation

// swiftlint:disable nesting
enum APIModels {
  struct HealthResponse: Codable {
    var status: String
    var version: String?
  }

  struct RepositoryResponse: Codable {
    var id: String
    var name: String
    var rootURL: String
    var worktreeCount: Int
  }

  struct RepositoryDetailResponse: Codable {
    var id: String
    var name: String
    var rootURL: String
    var worktrees: [WorktreeResponse]
  }

  struct WorktreeResponse: Codable {
    var id: String
    var name: String
    var detail: String
    var workingDirectory: String
    var repositoryRootURL: String
    var repositoryID: String?
    var isSelected: Bool?
    var createdAt: String?
  }

  struct RunScriptRequest: Codable {
    var script: String
  }

  struct CreateTerminalTabRequest: Codable {
    var input: String?
  }

  // MARK: - ACP (Agent Communication Protocol)

  struct AgentCard: Codable {
    var name: String
    var description: String
    var url: String
    var version: String?
    var capabilities: AgentCapabilities
    var skills: [AgentSkill]
    var provider: AgentProvider?
    var documentationUrl: String?
  }

  struct AgentCapabilities: Codable {
    var streaming: Bool
    var pushNotifications: Bool
  }

  struct AgentSkill: Codable {
    var id: String
    var name: String
    var description: String
    var inputSchema: InputSchema?
    var examples: [SkillExample]?

    struct InputSchema: Codable {
      var type: String
      var properties: [String: SchemaProperty]?
      var required: [String]?
    }

    struct SchemaProperty: Codable {
      var type: String
      var description: String?
    }

    struct SkillExample: Codable {
      var method: String
      var path: String
      var body: AnyCodable?
      var description: String
    }
  }

  struct AgentProvider: Codable {
    var organization: String
    var url: String?
  }
}
// swiftlint:enable nesting

/// Type-erased Codable wrapper for JSON values in examples.
struct AnyCodable: Codable {
  let value: Any

  init(_ value: Any) {
    self.value = value
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let dict = try? container.decode([String: AnyCodable].self) {
      value = dict.mapValues(\.value)
    } else if let array = try? container.decode([AnyCodable].self) {
      value = array.map(\.value)
    } else if let string = try? container.decode(String.self) {
      value = string
    } else if let int = try? container.decode(Int.self) {
      value = int
    } else if let bool = try? container.decode(Bool.self) {
      value = bool
    } else if let double = try? container.decode(Double.self) {
      value = double
    } else {
      value = NSNull()
    }
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case let dict as [String: Any]:
      try container.encode(dict.mapValues { AnyCodable($0) })
    case let array as [Any]:
      try container.encode(array.map { AnyCodable($0) })
    case let string as String:
      try container.encode(string)
    case let int as Int:
      try container.encode(int)
    case let bool as Bool:
      try container.encode(bool)
    case let double as Double:
      try container.encode(double)
    default:
      try container.encodeNil()
    }
  }
}
