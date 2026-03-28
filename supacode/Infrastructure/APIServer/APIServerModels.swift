import Foundation

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
}
