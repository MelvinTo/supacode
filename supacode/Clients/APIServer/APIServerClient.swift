import ComposableArchitecture

struct APIServerClient {
  var start: @MainActor @Sendable (UInt16) -> Void
  var stop: @MainActor @Sendable () -> Void
}

extension APIServerClient: DependencyKey {
  static let liveValue = APIServerClient(
    start: { _ in fatalError("APIServerClient.start not configured") },
    stop: { fatalError("APIServerClient.stop not configured") }
  )

  static let testValue = APIServerClient(
    start: { _ in },
    stop: {}
  )
}

extension DependencyValues {
  var apiServerClient: APIServerClient {
    get { self[APIServerClient.self] }
    set { self[APIServerClient.self] = newValue }
  }
}
