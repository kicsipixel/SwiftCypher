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
  case invalidHTTPResponse
  case invalidURL
  case jsonDecodingError
  case missingCredentials
  case missingDatabaseName(key: String)
  case clientError(statusCode: Int)
  case unsuccessfulRequest
}

extension SwiftCypherError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidHTTPResponse:
      return "Invalid HTTP response."
    case .invalidURL:
      return "Invalid URL. Please check it again."
    case .jsonDecodingError:
      return "JSON decoding error."
    case .missingCredentials:
      return "Missing credentials. Set the 'USERNAME/NEO4J_USER' and 'PASSWORD/NEO4J_PASSWORD' environment variables."
    case .missingDatabaseName(let key):
      return "Missing database name. Set the '\(key)' environment variable."
    case .clientError(let statusCode):
      return "Client error: \(statusCode)."
    case .unsuccessfulRequest:
      return "Unsuccessful request."
    }
  }
}
