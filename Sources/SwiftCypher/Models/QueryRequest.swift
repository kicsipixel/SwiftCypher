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

public struct QueryRequest: Encodable {
  public let statement: String
  public let parameters: [String: Neo4jValue]?
  public let includeCounters: Bool

  /// Creates a new Cypher query request.
  ///
  /// - Parameters:
  ///   - statement: The Cypher query string to execute, optionally referencing parameters with `$name` syntax.
  ///   - parameters: A dictionary of named parameters to bind into the query. Defaults to `nil`.
  ///   - includeCounters: Default is `true`, the response includes update statistics (nodes created, properties set, etc.).
  ///
  /// Example:
  /// ```swift
  /// let request = QueryRequest(
  ///   statement: "CREATE (n:Person {name: $name, age: $age})",
  ///   parameters: ["name": .string("Alice"), "age": .int(30)]
  /// )
  /// ```
  public init(statement: String, parameters: [String: Neo4jValue]? = nil, includeCounters: Bool = true) {
    self.statement = statement
    self.parameters = parameters
    self.includeCounters = includeCounters
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(statement, forKey: .statement)
    if let parameters {
      try container.encode(parameters, forKey: .parameters)
    }
    if includeCounters {
      try container.encode(true, forKey: .includeCounters)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case statement, parameters, includeCounters
  }
}
