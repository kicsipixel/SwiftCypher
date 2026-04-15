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

// MARK: - QueryCounters
public struct QueryCounters: Codable {
  public let nodesCreated: Int
  public let nodesDeleted: Int
  public let propertiesSet: Int
  public let relationshipsCreated: Int
  public let relationshipsDeleted: Int
  public let labelsAdded: Int
  public let labelsRemoved: Int
}

// MARK: - QueryResponse
/// Based on: https://neo4j.com/docs/query-api/current/typed-json/
public struct QueryResponse: Codable, Sequence {
  public typealias Element = [String: Neo4jValue]

  private let data: QueryData
  public let bookmarks: [String]
  public let counters: QueryCounters?

  public var fields: [String] {
    data.fields
  }

  public var rows: [[String: Neo4jValue]] {
    data.values.map { row in
      Dictionary(uniqueKeysWithValues: zip(data.fields, row))
    }
  }

  // MARK: Sequence conformance
  public func makeIterator() -> IndexingIterator<[[String: Neo4jValue]]> {
    rows.makeIterator()
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

  enum CodingKeys: String, CodingKey {
    case elementId = "_element_id"
    case labels = "_labels"
    case properties = "_properties"
  }
}

// MARK: - Neo4jValue
public enum Neo4jValue: Codable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null
  case date(String)
  case node(Neo4jNode)
  case list([Neo4jValue])
  case map([String: Neo4jValue])

  private enum TypedKeys: String, CodingKey {
    case type = "$type"
    case value = "_value"
  }

  public init(from decoder: Decoder) throws {
    // Typed JSON: {"$type": "...", "_value": ...}
    if let keyed = try? decoder.container(keyedBy: TypedKeys.self),
      let typeString = try? keyed.decode(String.self, forKey: .type)
    {
      switch typeString {
      case "Null": self = .null
      case "Boolean": self = .bool(try keyed.decode(Bool.self, forKey: .value))
      case "Integer": self = .int(Int(try keyed.decode(String.self, forKey: .value)) ?? 0)
      case "Float": self = .double(Double(try keyed.decode(String.self, forKey: .value)) ?? 0)
      case "String": self = .string(try keyed.decode(String.self, forKey: .value))
      case "Date": self = .date(try keyed.decode(String.self, forKey: .value))
      case "Node": self = .node(try keyed.decode(Neo4jNode.self, forKey: .value))
      case "List": self = .list(try keyed.decode([Neo4jValue].self, forKey: .value))
      case "Map": self = .map(try keyed.decode([String: Neo4jValue].self, forKey: .value))
      default: self = .null
      }
      return
    }

    // Plain JSON fallback
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
    var container = encoder.container(keyedBy: TypedKeys.self)
    switch self {
    case .null:
      try container.encode("Null", forKey: .type)
    case .bool(let v):
      try container.encode("Boolean", forKey: .type)
      try container.encode(v, forKey: .value)
    case .int(let v):
      try container.encode("Integer", forKey: .type)
      try container.encode(String(v), forKey: .value)
    case .double(let v):
      try container.encode("Float", forKey: .type)
      try container.encode(String(v), forKey: .value)
    case .string(let v):
      try container.encode("String", forKey: .type)
      try container.encode(v, forKey: .value)
    case .date(let v):
      try container.encode("Date", forKey: .type)
      try container.encode(v, forKey: .value)
    case .node(let v):
      try container.encode("Node", forKey: .type)
      try container.encode(v, forKey: .value)
    case .list(let v):
      try container.encode("List", forKey: .type)
      try container.encode(v, forKey: .value)
    case .map(let v):
      try container.encode("Map", forKey: .type)
      try container.encode(v, forKey: .value)
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
  public var dateValue: String? {
    if case .date(let v) = self { return v }
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
