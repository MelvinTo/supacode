import ComposableArchitecture
import Foundation
import Network

private nonisolated let apiServerLogger = SupaLogger("APIServer")

@MainActor
@Observable
final class APIServer {
  private(set) var isRunning = false
  private(set) var currentPort: UInt16 = 0
  private var listener: NWListener?
  private var store: StoreOf<AppFeature>?
  private let queue = DispatchQueue(label: "app.supabit.supacode.apiserver", qos: .userInitiated)

  func configure(store: StoreOf<AppFeature>) {
    self.store = store
  }

  func start(port: UInt16) {
    if isRunning && currentPort == port {
      return
    }
    if isRunning {
      stop()
    }

    do {
      let parameters = NWParameters.tcp
      parameters.requiredLocalEndpoint = NWEndpoint.hostPort(
        host: .ipv4(.loopback),
        port: NWEndpoint.Port(rawValue: port)!
      )
      let listener = try NWListener(using: parameters)
      self.listener = listener
      self.currentPort = port

      listener.stateUpdateHandler = { [weak self] state in
        Task { @MainActor [weak self] in
          self?.handleListenerState(state)
        }
      }

      listener.newConnectionHandler = { [weak self] connection in
        Task { @MainActor [weak self] in
          self?.handleConnection(connection)
        }
      }

      listener.start(queue: queue)
      apiServerLogger.info("Starting API server on 127.0.0.1:\(port)")
    } catch {
      apiServerLogger.warning("Failed to create API server listener: \(error)")
    }
  }

  func stop() {
    listener?.cancel()
    listener = nil
    isRunning = false
    currentPort = 0
    apiServerLogger.info("API server stopped")
  }

  // MARK: - Private

  private func handleListenerState(_ state: NWListener.State) {
    switch state {
    case .ready:
      isRunning = true
      apiServerLogger.info("API server ready on 127.0.0.1:\(currentPort)")
    case .failed(let error):
      apiServerLogger.warning("API server listener failed: \(error)")
      isRunning = false
    case .cancelled:
      isRunning = false
    default:
      break
    }
  }

  private func handleConnection(_ connection: NWConnection) {
    connection.start(queue: queue)
    receiveRequest(on: connection)
  }

  private nonisolated func receiveRequest(on connection: NWConnection) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] content, _, _, error in
      if let error {
        apiServerLogger.debug("Connection receive error: \(error)")
        connection.cancel()
        return
      }

      guard let data = content, !data.isEmpty else {
        connection.cancel()
        return
      }

      guard let request = HTTPRequestParser.parse(data) else {
        let response = HTTPResponse.badRequest(message: "Malformed HTTP request")
        self?.sendResponse(response, on: connection)
        return
      }

      Task { @MainActor [weak self] in
        guard let self, let store = self.store else {
          let response = HTTPResponse.internalError(message: "Server not configured")
          self?.sendResponse(response, on: connection)
          return
        }
        let response = APIServerRouter.handle(request, store: store)
        self.sendResponse(response, on: connection)
      }
    }
  }

  private nonisolated func sendResponse(_ response: HTTPResponse, on connection: NWConnection) {
    let data = response.serialize()
    connection.send(content: data, completion: .contentProcessed { _ in
      connection.cancel()
    })
  }
}
