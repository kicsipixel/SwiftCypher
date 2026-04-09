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

public enum SwiftCypherError: Error {
  case invalidURL
  case missingDatabaseName(key: String)
  case missingCredentials
}

extension SwiftCypherError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL. Please check it again."
    case .missingDatabaseName(let key):
      return "Missing database name. Set the '\(key)' environment variable."
    case .missingCredentials:
      return "Missing credentials. Set the 'USERNAME/NEO4J_USER' and 'PASSWORD/NEO4J_PASSWORD' environment variables."
    }
  }
}
