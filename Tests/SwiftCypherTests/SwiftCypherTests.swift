import Testing
@testable import SwiftCypher

@Test("basic test")
func simpleTest() async throws {
let client = SwiftCypherClient()
    try await client.runQuery()
}
