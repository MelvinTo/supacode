import Foundation

struct HTTPResponse: Sendable {
  var statusCode: Int
  var statusText: String
  var headers: [(String, String)]
  var body: Data?

  func serialize() -> Data {
    var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
    var allHeaders = headers
    if let body {
      allHeaders.append(("Content-Length", "\(body.count)"))
    } else {
      allHeaders.append(("Content-Length", "0"))
    }
    allHeaders.append(("Connection", "close"))
    for (name, value) in allHeaders {
      response += "\(name): \(value)\r\n"
    }
    response += "\r\n"
    var data = Data(response.utf8)
    if let body {
      data.append(body)
    }
    return data
  }
}

extension HTTPResponse {
  static func ok(json: some Encodable) -> HTTPResponse {
    jsonResponse(statusCode: 200, statusText: "OK", value: json)
  }

  static func accepted() -> HTTPResponse {
    jsonResponse(statusCode: 202, statusText: "Accepted", value: ["status": "accepted"])
  }

  static func notFound(message: String = "Not Found") -> HTTPResponse {
    jsonResponse(statusCode: 404, statusText: "Not Found", value: ["error": message])
  }

  static func badRequest(message: String) -> HTTPResponse {
    jsonResponse(statusCode: 400, statusText: "Bad Request", value: ["error": message])
  }

  static func methodNotAllowed() -> HTTPResponse {
    jsonResponse(statusCode: 405, statusText: "Method Not Allowed", value: ["error": "Method Not Allowed"])
  }

  static func internalError(message: String = "Internal Server Error") -> HTTPResponse {
    jsonResponse(statusCode: 500, statusText: "Internal Server Error", value: ["error": message])
  }

  private static func jsonResponse(statusCode: Int, statusText: String, value: some Encodable) -> HTTPResponse {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let body = (try? encoder.encode(value)) ?? Data("{}".utf8)
    return HTTPResponse(
      statusCode: statusCode,
      statusText: statusText,
      headers: [("Content-Type", "application/json")],
      body: body
    )
  }
}
