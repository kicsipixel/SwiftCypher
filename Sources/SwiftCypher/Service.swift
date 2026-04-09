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

public enum Service: String {
    case localhost, auroradb
    
    func getHost() -> String {
        switch self {
        case .localhost:
            return "localhost"
        case .auroradb:
            return "aurora.db.bluemix.net"
        }
    }
}
