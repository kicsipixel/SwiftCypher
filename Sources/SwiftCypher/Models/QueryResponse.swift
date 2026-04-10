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

// MARK: - QueryResponse
/// Based on: https://neo4j.com/docs/query-api/current/plain-json/
public struct QueryResponse: Codable {
  private let data: QueryData
  public let bookmarks: [String]

  public var fields: [String] {
    data.fields
  }

  public var rows: [[String: Neo4jValue]] {
    data.values.map { row in
      Dictionary(uniqueKeysWithValues: zip(data.fields, row))
    }
  }
}

// MARK: - QueryData
struct QueryData: Codable {
  let fields: [String]
  let values: [[Neo4jValue]]
}

// MARK: - Neo4jNode
public struct Neo4jNode: Codable {
  public let elementId: String
  public let labels: [String]
  public let properties: [String: Neo4jValue]
}

// MARK: - Neo4jValue
public enum Neo4jValue: Codable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null
  case node(Neo4jNode)
  case list([Neo4jValue])
  case map([String: Neo4jValue])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
      return
    }
    if let v = try? container.decode(Bool.self) {
      self = .bool(v)
      return
    }
    if let v = try? container.decode(Int.self) {
      self = .int(v)
      return
    }
    if let v = try? container.decode(Double.self) {
      self = .double(v)
      return
    }
    if let v = try? container.decode(String.self) {
      self = .string(v)
      return
    }
    if let v = try? container.decode(Neo4jNode.self) {
      self = .node(v)
      return
    }
    if let v = try? container.decode([Neo4jValue].self) {
      self = .list(v)
      return
    }
    if let v = try? container.decode([String: Neo4jValue].self) {
      self = .map(v)
      return
    }
    throw DecodingError.typeMismatch(
      Neo4jValue.self,
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Unsupported Neo4j value type"
      )
    )
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let v): try container.encode(v)
    case .int(let v): try container.encode(v)
    case .double(let v): try container.encode(v)
    case .bool(let v): try container.encode(v)
    case .null: try container.encodeNil()
    case .node(let v): try container.encode(v)
    case .list(let v): try container.encode(v)
    case .map(let v): try container.encode(v)
    }
  }
}

// MARK: - Neo4jValue convenience accessors
extension Neo4jValue {
  public var stringValue: String? {
    if case .string(let v) = self { return v }
    return nil
  }
  public var intValue: Int? {
    if case .int(let v) = self { return v }
    return nil
  }
  public var doubleValue: Double? {
    if case .double(let v) = self { return v }
    return nil
  }
  public var boolValue: Bool? {
    if case .bool(let v) = self { return v }
    return nil
  }
  public var nodeValue: Neo4jNode? {
    if case .node(let v) = self { return v }
    return nil
  }
  public var listValue: [Neo4jValue]? {
    if case .list(let v) = self { return v }
    return nil
  }
  public var mapValue: [String: Neo4jValue]? {
    if case .map(let v) = self { return v }
    return nil
  }
}
