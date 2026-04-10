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

  public init(statement: String, parameters: [String: Neo4jValue]? = nil) {
    self.statement = statement
    self.parameters = parameters
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(statement, forKey: .statement)
    if let parameters {
      try container.encode(parameters, forKey: .parameters)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case statement, parameters
  }
}
