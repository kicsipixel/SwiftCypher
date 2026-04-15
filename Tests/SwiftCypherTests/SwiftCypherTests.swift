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
  /// Simple query to test if the client can connect to Neo4j database.
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

  /// Query to create node and test `QueryCounters` model
  @Test("Client connects to local database and create node.")
  func localDBCreateNodeTest() async throws {
    guard let username = reader.string(forKey: "USERNAME"),
      let password = reader.string(forKey: "PASSWORD")
    else {
      throw SwiftCypherError.missingCredentials
    }

    let client = SwiftCypherClient(
      service: .localhost(database: "splitwise"),
      username: username,
      password: password
    )
    let name = "Szabolcs"
    let queryRequest = QueryRequest(statement: "CREATE (n:FRIEND {name: $name})", parameters: ["name": .string(name)])

    let response = try await client.runQuery(request: queryRequest)

    guard let nodesCreated = response.counters?.nodesCreated else {
      throw SwiftCypherError.unsuccessfulRequest
    }
    #expect(nodesCreated > 0)
  }

  // MARK: - Aurora/Remote database connection test
  // Test cannot be run from Xcode as it uses environment variables.
  @Test("Client connects to Aura/remote database, creates a node with a label.")
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

    /// `CREATE (n:FRIEND {name: 'Szabolcs'})`
    let request = QueryRequest(statement: "CREATE (szabolcs:FRIEND {name: $name})", parameters: ["name": .string("Szabolcs")])

    _ = try await client.runQuery(request: request)
  }

  // MARK: - Complex query
  // Test cannot be run from Xcode as it uses environment variables.
  @Test("Client connects to Aura/remote database, creates a node with different labels.")
  func remoteDBComplexQuery() async throws {
    guard let db = reader.string(forKey: "NEO4J_DATABASE") else {
      throw SwiftCypherError.missingDatabaseName(key: "NEO4J_DATABASE")
    }
    guard let username = reader.string(forKey: "NEO4J_USERNAME"),
      let password = reader.string(forKey: "NEO4J_PASSWORD")
    else {
      throw SwiftCypherError.missingCredentials
    }

    let client = SwiftCypherClient(service: .aura(database: db), username: username, password: password)

    /// `CREATE (event:EVENT {
    ///    name: 'Skiing in Tirol',
    ///    start_date: date('2026-02-01'),
    ///    end_date: date('2026-02-03'),
    ///    description: 'Weekend trip to the mountains'
    ///  })`
    let request = QueryRequest(
      statement: "CREATE (event:EVENT {name: $name, start_date: $start_date, end_date: $end_date, description: $description})",
      parameters: [
        "name": .string("Skiing in Tirol"),
        "start_date": .date("2026-02-01"),
        "end_date": .date("2026-02-03"),
        "description": .string("Weekend trip to the mountains"),
      ]
    )

    _ = try await client.runQuery(request: request)
  }

  // MARK: - Relationship
  // Test cannot be run from Xcode as it uses environment variables.
  @Test("Client connects to Aura/remote database, creates a relationship.")
  func remoteDBRelationship() async throws {
    guard let db = reader.string(forKey: "NEO4J_DATABASE") else {
      throw SwiftCypherError.missingDatabaseName(key: "NEO4J_DATABASE")
    }
    guard let username = reader.string(forKey: "NEO4J_USERNAME"),
      let password = reader.string(forKey: "NEO4J_PASSWORD")
    else {
      throw SwiftCypherError.missingCredentials
    }

    let client = SwiftCypherClient(service: .aura(database: db), username: username, password: password)

    /// `MATCH (alice:FRIEND {name: 'Alice'}),
    ///     (bob:FRIEND {name: 'Bob'}),
    ///     (charles:FRIEND {name: 'Charles'}),
    ///      (event:EVENT {name: 'Skiing in Tirol'})
    /// CREATE (coffee:ACTIVITY {
    ///   item: 'Coffee',
    ///   date: date('2026-02-01'),
    ///   totalAmount: 15.00,
    ///    currency: 'EUR'
    ///  })
    ///  CREATE (bob)-[:PAID_FOR {amount: 15.00}]->(coffee),
    ///         (alice)-[:PARTICIPATED_IN]->(coffee),
    ///         (charles)-[:PARTICIPATED_IN]->(coffee),
    ///         (coffee)-[:BELONGS_TO]->(event)`
    let request = QueryRequest(
      statement: """
        MATCH (alice:FRIEND {name: $aliceName}),
              (bob:FRIEND {name: $bobName}),
              (charles:FRIEND {name: $charlesName}),
              (event:EVENT {name: $eventName})
        CREATE (coffee:ACTIVITY {
          item: $item,
          date: date($activityDate),
          totalAmount: $totalAmount,
          currency: $currency
        })
        CREATE (bob)-[:PAID_FOR {amount: $amount}]->(coffee),
               (alice)-[:PARTICIPATED_IN]->(coffee),
               (charles)-[:PARTICIPATED_IN]->(coffee),
               (coffee)-[:BELONGS_TO]->(event)
        """,
      parameters: [
        "aliceName": .string("Alice"),
        "bobName": .string("Bob"),
        "charlesName": .string("Charles"),
        "eventName": .string("Skiing in Tirol"),
        "item": .string("Pizza"),
        "activityDate": .date("2026-02-01"),
        "totalAmount": .double(45.00),
        "currency": .string("EUR"),
        "amount": .double(45.00),
      ]
    )

    _ = try await client.runQuery(request: request)
  }
}
