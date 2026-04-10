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

public enum Service {
  case localhost(database: String = "neo4j")
  case aura(database: String)

  var url: String {
    switch self {
    case .localhost(let database):
      return "http://localhost:7474/db/\(database)/query/v2"
    case .aura(let database):
      return "https://\(database).databases.neo4j.io/db/\(database)/query/v2"
    }
  }
}
