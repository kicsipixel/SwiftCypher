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

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct SwiftCypherClient: Sendable {
  let hostURL: String
  let username: String
  let password: String
  let logger: Logger

  private init(service: Service = .localhost(), username: String = "neo4j", password: String, logger: Logger = Logger(label: "SwiftCypherClient")) {
    self.hostURL = service.url
    self.username = username
    self.password = password
    self.logger = logger
  }

  // MARK: - connect
  /// Creates a client and waits until Neo4j is ready, retrying up to 10 times with 1-second intervals.
  /// ```swift
  /// let client = try await SwiftCypherClient.connect(password: "password")
  /// ```
  public static func connect(
    service: Service = .localhost(),
    username: String = "neo4j",
    password: String,
    logger: Logger = Logger(label: "SwiftCypherClient")
  ) async throws -> SwiftCypherClient {
    let client = SwiftCypherClient(service: service, username: username, password: password, logger: logger)
    var attempts = 0
    while true {
      do {
        try await client.ping()
        logger.info("Connected to Neo4j at \(service.url)")
        return client
      } catch {
        attempts += 1
        guard attempts < 10 else {
          logger.error("Failed to connect to Neo4j after \(attempts) attempts")
          throw error
        }
        logger.warning("Neo4j not ready, retrying (\(attempts)/10)...")
        try await Task.sleep(for: .seconds(1))
      }
    }
  }

  // MARK: - ping
  /// Sends a lightweight query to verify the connection is alive.
  public func ping() async throws {
    let request = QueryRequest(statement: "RETURN 1")
    _ = try await runQuery(request: request)
  }

  // MARK: - runs a query
  /// The server wraps the submitted Cypher query in a (implicit) transaction for you.
  /// Each request must include an Authorization header.
  /// ```
  /// let request = QueryRequest(
  ///   statement: "MERGE (n:Person {name: $name, age: $age}) RETURN n AS alice",
  ///   parameters: [
  ///       "name": .string("Alice"),
  ///       "age": .int(42)
  //   ]
  /// )
  ///   ```
  ///
  public func runQuery(request: QueryRequest) async throws -> QueryResponse {
    guard let url = URL(string: "\(hostURL)") else {
      Logger(label: "SwiftCypherClient").error("Invalid URL")
      throw SwiftCypherError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/vnd.neo4j.query", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("application/vnd.neo4j.query", forHTTPHeaderField: "Accept")
    let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
    urlRequest.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

    urlRequest.httpBody = try JSONEncoder().encode(request)
    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw SwiftCypherError.invalidHTTPResponse
    }

    // `202: Accepted`
    if httpResponse.statusCode != 202 {
      let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
      logger.error("Unexpected status code: \(httpResponse.statusCode), body: \(body)")
      throw SwiftCypherError.unsuccessfulRequest
    }

    do {
      let response = try JSONDecoder().decode(QueryResponse.self, from: data)
      return response
    }
    catch {
      throw SwiftCypherError.jsonDecodingError
    }
  }
}
