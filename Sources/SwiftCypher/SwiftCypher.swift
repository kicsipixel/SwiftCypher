////===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCypher open source project
//
// Copyright (c) 2026 Szabolcs Tóth and the SwiftCypher project authors
// Licensed under MIT License
//
// See LICENSE for license information
// See CONTRIBUTORS.md for the list of SwiftCypher project authors
//
// SPDX-License-Identifier: MIT License
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging

public struct SwiftCypherClient {
  let hostURL: String
  let username: String
  let password: String

  public init(service: Service = .localhost(), username: String = "neo4j", password: String) {
    self.hostURL = service.url
    self.username = username
    self.password = password
  }

  // MARK: - runs a query
  /// The server wraps the submitted Cypher query in a (implicit) transaction for you.
  /// Each request must include an Authorization header.
  public func runQuery() async throws {
    guard let url = URL(string: "\(hostURL)") else {
      Logger(label: "SwiftCypherClient").error("Invalid URL")
      throw SwiftCypherError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
    urlRequest.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

    let body = ["statement": "MATCH (n:Person) RETURN n.name"]
    urlRequest.httpBody = try JSONEncoder().encode(body)
    let (_, response) = try await URLSession.shared.data(for: urlRequest)
    print(response)
  }
}
