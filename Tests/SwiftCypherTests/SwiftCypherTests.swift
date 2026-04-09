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

  // MARK: -
  @Test("Test if client can conect to local database.")
  func localDBConnectionTest() async throws {
    guard let username = reader.string(forKey: "USERNAME"),
      let password = reader.string(forKey: "PASSWORD")
    else {
      throw SwiftCypherError.missingCredentials
    }
    let client = SwiftCypherClient(username: username, password: password)
    try await client.runQuery()
  }

  // MARK: -
  @Test("Test if client can conect to remote database.")
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
    try await client.runQuery()
  }
}
