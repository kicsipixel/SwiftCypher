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
  let credential: Credential
  let logger: Logger

  private init(service: Service = .localhost(), credential: Credential, logger: Logger = Logger(label: "SwiftCypherClient")) {
    self.hostURL = service.url
    self.credential = credential
    self.logger = logger
  }

  // MARK: - connect
  /// Creates a client and waits until Neo4j is ready, retrying up to 10 times with 1-second intervals.
  /// ```swift
  /// let client = try await SwiftCypherClient.connect(password: "password")
  /// ```
  public static func connect(
    service: Service = .localhost(),
    credential: Credential,
    logger: Logger = Logger(label: "SwiftCypherClient")
  ) async throws -> SwiftCypherClient {
    let client = SwiftCypherClient(service: service, credential: credential, logger: logger)
    var attempts = 0
    while true {
      do {
        try await client.ping()
        logger.info("Connected to Neo4j at \(service.url)")
        return client
      }
      catch {
        attempts += 1
        guard attempts < 10 else {
          logger.error("Failed to connect to Neo4j after \(attempts) attempts")
          throw error
        }
        logger.warning("Neo4j not ready, retrying (\(attempts)/10)...")
        try await Task.sleep(for: .seconds(1.5))
      }
    }
  }

  public static func connect(
    service: Service = .localhost(),
    username: String = "neo4j",
    password: String,
    logger: Logger = Logger(label: "SwiftCypherClient")
  ) async throws -> SwiftCypherClient {
    try await connect(service: service, credential: .basic(username: username, password: password), logger: logger)
  }

  // MARK: - ping
  /// Sends a lightweight query to verify the connection is alive.
  public func ping() async throws {
    _ = try await _runQuery(request: QueryRequest(statement: "RETURN 1"))
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
    do {
      return try await _runQuery(request: request)
    }
    catch SwiftCypherError.clientError(let statusCode, let neo4jCode, let message) {
      logger.error("Query rejected with \(statusCode)\(neo4jCode.map { " [\($0)]" } ?? "")\(message.map { ": \($0)" } ?? "") — not retrying.")
      throw SwiftCypherError.clientError(statusCode: statusCode, neo4jCode: neo4jCode, message: message)
    }
    catch {
      logger.warning("Query failed (\(error)) — waiting for Neo4j to recover...")
      try await reconnect()
      logger.info("Reconnected, retrying query...")
      return try await _runQuery(request: request)
    }
  }

  // MARK: - reconnect
  private func reconnect() async throws {
    var attempts = 0
    while true {
      do {
        try await ping()
        return
      }
      catch {
        attempts += 1
        guard attempts < 10 else {
          logger.error("Neo4j did not recover after \(attempts) attempts")
          throw error
        }
        logger.warning("Neo4j not responding, retrying (\(attempts)/10)...")
        try await Task.sleep(for: .seconds(1.5))
      }
    }
  }

  private func _runQuery(request: QueryRequest) async throws -> QueryResponse {
    guard let url = URL(string: "\(hostURL)") else {
      Logger(label: "SwiftCypherClient").error("Invalid URL")
      throw SwiftCypherError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/vnd.neo4j.query.v1.1", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("application/vnd.neo4j.query", forHTTPHeaderField: "Accept")
    urlRequest.setValue("close", forHTTPHeaderField: "Connection")
    switch credential {
    case .basic(let username, let password):
      let encoded = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
      urlRequest.addValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
    case .bearer(let token):
      urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    urlRequest.httpBody = try JSONEncoder().encode(request)
    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw SwiftCypherError.invalidHTTPResponse
    }

    // `202: Accepted`
    if httpResponse.statusCode != 202 {
      let neo4jCode = (try? JSONDecoder().decode(Neo4jErrorResponse.self, from: data))?.errors.first?.code
      let neo4jMessage = (try? JSONDecoder().decode(Neo4jErrorResponse.self, from: data))?.errors.first?.message
      logger.error("Unexpected status \(httpResponse.statusCode)\(neo4jCode.map { " [\($0)]" } ?? "")\(neo4jMessage.map { ": \($0)" } ?? "")")
      if (400..<500).contains(httpResponse.statusCode) {
        throw SwiftCypherError.clientError(statusCode: httpResponse.statusCode, neo4jCode: neo4jCode, message: neo4jMessage)
      }
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

private struct Neo4jErrorResponse: Decodable {
  struct Neo4jError: Decodable {
    let code: String
    let message: String
  }
  let errors: [Neo4jError]
}
