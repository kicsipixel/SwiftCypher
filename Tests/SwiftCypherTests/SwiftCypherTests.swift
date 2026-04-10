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

import Configuration
import Logging
import Testing

@testable import SwiftCypher

struct SwiftCypherTests {
  let reader: ConfigReader

  init() async throws {
    reader = try await ConfigReader(providers: [
      CommandLineArgumentsProvider(),
      EnvironmentVariablesProvider(),
      EnvironmentVariablesProvider(environmentFilePath: ".env", allowMissing: true),
    ])
  }

  // MARK: - Local database test
  // Test cannot be run from Xcode as it uses environment variables.
  @Test("Client connects to local database and makes a simple query.")
  func localDBConnectionTest() async throws {
    guard let username = reader.string(forKey: "USERNAME"),
      let password = reader.string(forKey: "PASSWORD")
    else {
      throw SwiftCypherError.missingCredentials
    }

    let client = SwiftCypherClient(username: username, password: password)
    let request = QueryRequest(statement: "MATCH (n:FRIEND) RETURN n.name")

    let response = try await client.runQuery(request: request)

    // Print response if it is not empty
    for row in response.rows {
      if let name = row["n.name"]?.stringValue {
        print(name)
      }
    }
  }

  // MARK: - Aurora/Remote database connection test
  // Test cannot be run from Xcode as it uses environment variables.
  @Test("Client connects to Aurora/remote database, create a node with a label.")
  func remoteDBConnectionTest() async throws {
    guard let db = reader.string(forKey: "NEO4J_DATABASE") else {
      throw SwiftCypherError.missingDatabaseName(key: "NEO4J_DATABASE")
    }
    guard let username = reader.string(forKey: "NEO4J_USERNAME"),
      let password = reader.string(forKey: "NEO4J_PASSWORD")
    else {
      throw SwiftCypherError.missingCredentials
    }

    let client = SwiftCypherClient(service: .aura(database: db), username: username, password: password)

    /// `CREATE (alice:FRIEND {name: 'Szabolcs'})`
    let request = QueryRequest(statement: "CREATE (szabolcs:FRIEND {name: $name})", parameters: ["name": .string("Szabolcs")])

    _ = try await client.runQuery(request: request)
  }
}
