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
import Foundation
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

  @Test("Client connects to local database.")
  func localDatabaseConnectionTest() async throws {
    guard let username = reader.string(forKey: "USERNAME"),
      let password = reader.string(forKey: "PASSWORD")
    else { throw SwiftCypherError.missingCredentials }

    let database = reader.string(forKey: "DATABASE") ?? "neo4j"

    let client = try await SwiftCypherClient.connect(
      service: .localhost(database: database),
      username: username,
      password: password
    )

    let response = try await client.runQuery(request: QueryRequest(statement: "MATCH (n) RETURN n LIMIT 1"))
    #expect(response.fields.isEmpty == false)
  }

  @Test("Client connects to local database using Credential.")
  func localDatabaseCredentialTest() async throws {
    guard let username = reader.string(forKey: "USERNAME"),
      let password = reader.string(forKey: "PASSWORD")
    else { throw SwiftCypherError.missingCredentials }

    let database = reader.string(forKey: "DATABASE") ?? "neo4j"

    let client = try await SwiftCypherClient.connect(
      service: .localhost(database: database),
      credential: .basic(username: username, password: password)
    )

    let response = try await client.runQuery(request: QueryRequest(statement: "MATCH (n) RETURN n LIMIT 1"))
    #expect(response.fields.isEmpty == false)
  }

  @Test("Creates a Person node in local database.")
  func localDatabaseCreatePersonTest() async throws {
    guard let username = reader.string(forKey: "USERNAME"),
      let password = reader.string(forKey: "PASSWORD")
    else { throw SwiftCypherError.missingCredentials }

    let database = reader.string(forKey: "DATABASE") ?? "neo4j"

    let client = try await SwiftCypherClient.connect(
      service: .localhost(database: database),
      username: username,
      password: password
    )

    let personId = UUID().uuidString

    let response = try await client.runQuery(
      request: QueryRequest(
        statement: "CREATE (n:Person {name: $name, person_id: $person_id, created_at: $created_at}) RETURN n",
        parameters: [
          "name": .string("Szabolcs"),
          "person_id": .string(personId),
          "created_at": .date("2026-04-22"),
        ]
      )
    )

    let node = response.rows.first?["n"]?.nodeValue
    #expect(node?.properties["name"]?.stringValue == "Szabolcs")
    #expect(node?.properties["person_id"]?.stringValue == personId)
    #expect(node?.properties["created_at"]?.dateValue == "2026-04-22")
  }
}
