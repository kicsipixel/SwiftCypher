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

struct Result: Codable {
      let data: QueryData
      let bookmarks: [String]
  }

  struct QueryData: Codable {
      let fields: [String]
      let values: [[Neo4jValue]]
  }

  enum Neo4jValue: Codable {
      case string(String)
      case int(Int)
      case double(Double)
      case bool(Bool)
      case null
      case node(Neo4jNode)
      case list([Neo4jValue])
      case map([String: Neo4jValue])

      init(from decoder: Decoder) throws {
          let container = try decoder.singleValueContainer()
          if container.decodeNil() { self = .null; return }
          if let v = try? container.decode(Bool.self)          { self = .bool(v);   return }
          if let v = try? container.decode(Int.self)           { self = .int(v);    return }
          if let v = try? container.decode(Double.self)        { self = .double(v); return }
          if let v = try? container.decode(String.self)        { self = .string(v); return }
          if let v = try? container.decode(Neo4jNode.self)     { self = .node(v);   return }
          if let v = try? container.decode([Neo4jValue].self)  { self = .list(v);   return }
          if let v = try? container.decode([String: Neo4jValue].self) { self = .map(v); return }
          throw DecodingError.typeMismatch(Neo4jValue.self, DecodingError.Context(
              codingPath: decoder.codingPath,
              debugDescription: "Unsupported Neo4j value type"
          ))
      }

      func encode(to encoder: Encoder) throws {
          var container = encoder.singleValueContainer()
          switch self {
          case .string(let v):  try container.encode(v)
          case .int(let v):     try container.encode(v)
          case .double(let v):  try container.encode(v)
          case .bool(let v):    try container.encode(v)
          case .null:           try container.encodeNil()
          case .node(let v):    try container.encode(v)
          case .list(let v):    try container.encode(v)
          case .map(let v):     try container.encode(v)
          }
      }
  }

  struct Neo4jNode: Codable {
      let elementId: String
      let labels: [String]
      let properties: [String: Neo4jValue]  // dynamic — any key, any value
  }

