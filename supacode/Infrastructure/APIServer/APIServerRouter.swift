import ComposableArchitecture
import Foundation

@MainActor
enum APIServerRouter {

  static func handle(_ request: HTTPRequest, store: StoreOf<AppFeature>) -> HTTPResponse {
    let path = request.path
    let method = request.method

    // Strip query string if present
    let routePath = path.split(separator: "?", maxSplits: 1).first.map(String.init) ?? path

    // All routes must start with /api/v1
    guard routePath.hasPrefix("/api/v1/") || routePath == "/api/v1" else {
      return .notFound(message: "Expected /api/v1 prefix")
    }

    let stripped = String(routePath.dropFirst("/api/v1/".count))
    let segments = stripped.split(separator: "/").map(String.init)

    return dispatch(method: method, segments: segments, request: request, store: store)
  }

  // MARK: - Dispatch

  private static func dispatch(
    method: String,
    segments: [String],
    request: HTTPRequest,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    let count = segments.count

    // GET /health
    if method == "GET", count == 1, segments[0] == "health" {
      return handleHealth()
    }

    // GET /repositories
    if method == "GET", count == 1, segments[0] == "repositories" {
      return handleListRepositories(store: store)
    }

    // GET /repositories/:id
    if method == "GET", count == 2, segments[0] == "repositories" {
      return handleGetRepository(id: segments[1], store: store)
    }

    // GET /repositories/:id/worktrees
    if method == "GET", count == 3, segments[0] == "repositories", segments[2] == "worktrees" {
      return handleListWorktrees(repositoryID: segments[1], store: store)
    }

    // POST /repositories/:id/worktrees
    if method == "POST", count == 3, segments[0] == "repositories", segments[2] == "worktrees" {
      return handleCreateWorktree(repositoryID: segments[1], store: store)
    }

    // GET /worktrees/:id
    if method == "GET", count == 2, segments[0] == "worktrees" {
      return handleGetWorktree(id: segments[1], store: store)
    }

    // POST /worktrees/:id/select
    if method == "POST", count == 3, segments[0] == "worktrees", segments[2] == "select" {
      return handleSelectWorktree(id: segments[1], store: store)
    }

    // POST /worktrees/:id/archive
    if method == "POST", count == 3, segments[0] == "worktrees", segments[2] == "archive" {
      return handleArchiveWorktree(id: segments[1], store: store)
    }

    // POST /worktrees/:id/unarchive
    if method == "POST", count == 3, segments[0] == "worktrees", segments[2] == "unarchive" {
      return handleUnarchiveWorktree(id: segments[1], store: store)
    }

    // DELETE /worktrees/:id
    if method == "DELETE", count == 2, segments[0] == "worktrees" {
      return handleDeleteWorktree(id: segments[1], store: store)
    }

    // POST /worktrees/:id/terminal/tab
    if method == "POST", count == 4,
      segments[0] == "worktrees", segments[2] == "terminal", segments[3] == "tab"
    {
      return handleCreateTerminalTab(worktreeID: segments[1], store: store)
    }

    // POST /worktrees/:id/terminal/close-tab
    if method == "POST", count == 4,
      segments[0] == "worktrees", segments[2] == "terminal", segments[3] == "close-tab"
    {
      return handleCloseTerminalTab(worktreeID: segments[1], store: store)
    }

    // POST /worktrees/:id/terminal/run-script
    if method == "POST", count == 4,
      segments[0] == "worktrees", segments[2] == "terminal", segments[3] == "run-script"
    {
      return handleRunScript(worktreeID: segments[1], request: request, store: store)
    }

    // POST /worktrees/:id/terminal/stop-script
    if method == "POST", count == 4,
      segments[0] == "worktrees", segments[2] == "terminal", segments[3] == "stop-script"
    {
      return handleStopScript(worktreeID: segments[1], store: store)
    }

    return .notFound()
  }

  // MARK: - Health

  private static func handleHealth() -> HTTPResponse {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    return .ok(json: APIModels.HealthResponse(status: "ok", version: version))
  }

  // MARK: - Repositories

  private static func handleListRepositories(store: StoreOf<AppFeature>) -> HTTPResponse {
    let repositories = store.repositories.repositories.map { repo in
      APIModels.RepositoryResponse(
        id: repo.id,
        name: repo.name,
        rootURL: repo.rootURL.path(percentEncoded: false),
        worktreeCount: repo.worktrees.count
      )
    }
    return .ok(json: repositories)
  }

  private static func handleGetRepository(
    id: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard let repo = store.repositories.repositories[id: id] else {
      return .notFound(message: "Repository not found")
    }
    let selectedID = store.repositories.selectedWorktreeID
    let response = APIModels.RepositoryDetailResponse(
      id: repo.id,
      name: repo.name,
      rootURL: repo.rootURL.path(percentEncoded: false),
      worktrees: repo.worktrees.map {
        worktreeResponse($0, selectedWorktreeID: selectedID, repositoryID: repo.id)
      }
    )
    return .ok(json: response)
  }

  private static func handleListWorktrees(
    repositoryID: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard let repo = store.repositories.repositories[id: repositoryID] else {
      return .notFound(message: "Repository not found")
    }
    let selectedID = store.repositories.selectedWorktreeID
    let worktrees = repo.worktrees.map {
      worktreeResponse($0, selectedWorktreeID: selectedID, repositoryID: repo.id)
    }
    return .ok(json: worktrees)
  }

  private static func handleCreateWorktree(
    repositoryID: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.repositories[id: repositoryID] != nil else {
      return .notFound(message: "Repository not found")
    }
    store.send(.repositories(.createRandomWorktreeInRepository(repositoryID)))
    return .accepted()
  }

  // MARK: - Worktrees

  private static func handleGetWorktree(
    id: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard let worktree = store.repositories.worktree(for: id) else {
      return .notFound(message: "Worktree not found")
    }
    let repositoryID = store.repositories.repositoryID(containing: worktree.id)
    let selectedID = store.repositories.selectedWorktreeID
    return .ok(
      json: worktreeResponse(
        worktree,
        selectedWorktreeID: selectedID,
        repositoryID: repositoryID
      )
    )
  }

  private static func handleSelectWorktree(
    id: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: id) != nil else {
      return .notFound(message: "Worktree not found")
    }
    store.send(.repositories(.selectWorktree(id)))
    return .accepted()
  }

  private static func handleArchiveWorktree(
    id: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: id) != nil else {
      return .notFound(message: "Worktree not found")
    }
    guard let repositoryID = store.repositories.repositoryID(containing: id) else {
      return .notFound(message: "Repository not found for worktree")
    }
    store.send(.repositories(.requestArchiveWorktree(id, repositoryID)))
    return .accepted()
  }

  private static func handleUnarchiveWorktree(
    id: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: id) != nil else {
      return .notFound(message: "Worktree not found")
    }
    store.send(.repositories(.unarchiveWorktree(id)))
    return .accepted()
  }

  private static func handleDeleteWorktree(
    id: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: id) != nil else {
      return .notFound(message: "Worktree not found")
    }
    guard let repositoryID = store.repositories.repositoryID(containing: id) else {
      return .notFound(message: "Repository not found for worktree")
    }
    store.send(.repositories(.requestDeleteWorktree(id, repositoryID)))
    return .accepted()
  }

  // MARK: - Terminal

  private static func handleCreateTerminalTab(
    worktreeID: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: worktreeID) != nil else {
      return .notFound(message: "Worktree not found")
    }
    store.send(.repositories(.selectWorktree(worktreeID)))
    store.send(.newTerminal)
    return .accepted()
  }

  private static func handleCloseTerminalTab(
    worktreeID: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: worktreeID) != nil else {
      return .notFound(message: "Worktree not found")
    }
    store.send(.repositories(.selectWorktree(worktreeID)))
    store.send(.closeTab)
    return .accepted()
  }

  private static func handleRunScript(
    worktreeID: String,
    request: HTTPRequest,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: worktreeID) != nil else {
      return .notFound(message: "Worktree not found")
    }
    guard let body = request.body, !body.isEmpty else {
      return .badRequest(message: "Request body with 'script' field is required")
    }
    guard let scriptRequest = try? JSONDecoder().decode(
      APIModels.RunScriptRequest.self,
      from: body
    ) else {
      return .badRequest(message: "Invalid JSON body, expected {\"script\": \"...\"}")
    }
    store.send(.repositories(.selectWorktree(worktreeID)))
    store.send(.runScriptDraftChanged(scriptRequest.script))
    store.send(.runScriptPromptPresented(true))
    store.send(.saveRunScriptAndRun)
    return .accepted()
  }

  private static func handleStopScript(
    worktreeID: String,
    store: StoreOf<AppFeature>
  ) -> HTTPResponse {
    guard store.repositories.worktree(for: worktreeID) != nil else {
      return .notFound(message: "Worktree not found")
    }
    store.send(.repositories(.selectWorktree(worktreeID)))
    store.send(.stopRunScript)
    return .accepted()
  }

  // MARK: - Helpers

  private static func worktreeResponse(
    _ worktree: Worktree,
    selectedWorktreeID: Worktree.ID?,
    repositoryID: Repository.ID?
  ) -> APIModels.WorktreeResponse {
    var createdAt: String?
    if let date = worktree.createdAt {
      createdAt = ISO8601DateFormatter().string(from: date)
    }
    return APIModels.WorktreeResponse(
      id: worktree.id,
      name: worktree.name,
      detail: worktree.detail,
      workingDirectory: worktree.workingDirectory.path(percentEncoded: false),
      repositoryRootURL: worktree.repositoryRootURL.path(percentEncoded: false),
      repositoryID: repositoryID,
      isSelected: worktree.id == selectedWorktreeID,
      createdAt: createdAt
    )
  }
}
