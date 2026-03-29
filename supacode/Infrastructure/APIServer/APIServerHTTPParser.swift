import Foundation

nonisolated struct HTTPRequest: Sendable {
  let method: String
  let path: String
  let headers: [(String, String)]
  let body: Data?
}

nonisolated enum HTTPRequestParser {
  static func parse(_ data: Data) -> HTTPRequest? {
    guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) else {
      return nil
    }
    guard let headerString = String(data: data[data.startIndex..<headerEnd.lowerBound], encoding: .utf8) else {
      return nil
    }
    let lines = headerString.split(separator: "\r\n", omittingEmptySubsequences: false)
    guard let requestLine = lines.first else { return nil }
    let parts = requestLine.split(separator: " ", maxSplits: 2)
    guard parts.count >= 2 else { return nil }
    let method = String(parts[0])
    let path = String(parts[1])
    var headers: [(String, String)] = []
    for line in lines.dropFirst() {
      guard let colonIndex = line.firstIndex(of: ":") else { continue }
      let name = line[line.startIndex..<colonIndex].trimmingCharacters(in: .whitespaces).lowercased()
      let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
      headers.append((name, value))
    }
    let bodyStart = headerEnd.upperBound
    var body: Data?
    if bodyStart < data.endIndex {
      body = data[bodyStart...]
    }
    if let contentLengthHeader = headers.first(where: { $0.0 == "content-length" }),
      let contentLength = Int(contentLengthHeader.1),
      contentLength > 0
    {
      if let body, body.count < contentLength {
        return nil  // Incomplete body
      }
    }
    return HTTPRequest(method: method, path: path, headers: headers, body: body)
  }
}
