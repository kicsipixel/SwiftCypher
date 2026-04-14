# SwiftCypher

A lightweight, idiomatic Swift client for the [Neo4j Query API](https://neo4j.com/docs/query-api/current/) (v2). Execute Cypher queries over HTTPS from any Swift platform — iOS, macOS, or Linux — with no Bolt driver required.

![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue.svg)
![MIT License](https://img.shields.io/badge/license-MIT-green.svg)

---

## Features

- Pure Swift, zero native dependencies — works on macOS, iOS, and Linux
- Async/await API built on `URLSession`
- Supports local Neo4j instances and [Neo4j Aura](https://neo4j.com/cloud/platform/aura-graph-database/) (cloud)
- Typed response values: `String`, `Integer`, `Float`, `Boolean`, `Date`, `Node`, `List`, `Map`
- Typed JSON responses via `application/vnd.neo4j.query.v1.1` — no ambiguous types
- Parameterized queries to prevent Cypher injection and improve query plan caching
- Credentials loaded from environment variables or `.env` files via [swift-configuration](https://github.com/apple/swift-configuration)

---

## Requirements

| Platform | Minimum |
|----------|---------|
| macOS    | 15.0+   |
| iOS      | 18.0+   |

- **Neo4j:** 5.19+ (Query API v2)
- **Swift:** 6.0+

---

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kicsipixel/SwiftCypher", from: "0.0.1")
]
```

Then add `SwiftCypher` to your target's dependencies:

```swift
    .product(name: "SwiftCypher", package: "SwiftCypher"),
```

Or via Xcode: **File → Add Package Dependencies** and paste the repository URL.

---

## Quick Start

```swift
import SwiftCypher

let client = SwiftCypherClient(username: "neo4j", password: "yourpassword")
let request = QueryRequest(statement: "MATCH (n:Person) RETURN n.name")
let response = try await client.runQuery(request: request)

for row in response.rows {
    print(row["n.name"]?.stringValue ?? "")
}
```

---

## Connecting to Neo4j

Credentials should be read from environment variables or a `.env` file — never hardcoded.

### Local instance (default)

```swift
let client = SwiftCypherClient(username: username, password: password)
// → http://localhost:7474/db/neo4j/query/v2
```

### Local instance with a custom database

```swift
let client = SwiftCypherClient(
    service: .localhost(database: "mydb"),
    username: username,
    password: password
)
```

### Neo4j Aura (cloud)

```swift
let client = SwiftCypherClient(
    service: .aura(database: db),
    username: username,
    password: password
)
// → https://<db>.databases.neo4j.io/db/<db>/query/v2
```

### `.env` file

```
# Local
USERNAME=neo4j
PASSWORD=yourpassword

# Aura
NEO4J_DATABASE=your-aura-instance-id
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your-aura-password
```

| Service | URL |
|---------|-----|
| `.localhost(database:)` | `http://localhost:7474/db/{database}/query/v2` |
| `.aura(database:)` | `https://{database}.databases.neo4j.io/db/{database}/query/v2` |

---

## Running Queries

### Read

```swift
let request = QueryRequest(statement: "MATCH (n:Person) RETURN n.name, n.age")
let response = try await client.runQuery(request: request)
```

### Write with parameters

Always prefer parameterized queries over string interpolation — they prevent Cypher injection and enable server-side query plan caching.

```swift
let request = QueryRequest(
    statement: "CREATE (n:Person {name: $name, age: $age})",
    parameters: [
        "name": .string("Alice"),
        "age": .int(30),
    ]
)
_ = try await client.runQuery(request: request)
```

### Relationships

```swift
let request = QueryRequest(
    statement: """
        MATCH (alice:Person {name: $alice}), (bob:Person {name: $bob})
        CREATE (alice)-[:KNOWS]->(bob)
        """,
    parameters: [
        "alice": .string("Alice"),
        "bob": .string("Bob"),
    ]
)
```

### Dates

Pass dates as `.date("yyyy-MM-dd")` and wrap with `date()` in the Cypher statement:

```swift
let request = QueryRequest(
    statement: """
        CREATE (e:Event {
            name: $name,
            start_date: date($startDate),
            end_date: date($endDate)
        })
        """,
    parameters: [
        "name": .string("Skiing in Tirol"),
        "startDate": .date("2026-02-01"),
        "endDate": .date("2026-02-03"),
    ]
)
```

---

## Working with Results

`QueryResponse` exposes:

| Property | Type | Description |
|----------|------|-------------|
| `rows` | `[[String: Neo4jValue]]` | Results keyed by field name |
| `fields` | `[String]` | Column names from the `RETURN` clause |
| `bookmarks` | `[String]` | Opaque tokens for causal consistency chaining |

```swift
for row in response.rows {
    let name   = row["n.name"]?.stringValue    // String?
    let age    = row["n.age"]?.intValue        // Int?
    let score  = row["n.score"]?.doubleValue   // Double?
    let active = row["n.active"]?.boolValue    // Bool?
    let joined = row["n.joined"]?.dateValue    // String? (ISO 8601)
    let node   = row["n"]?.nodeValue           // Neo4jNode?
}
```

### Nodes

```swift
if let node = row["n"]?.nodeValue {
    print(node.elementId)               // "4:abc123:0"
    print(node.labels)                  // ["Person"]
    print(node.properties["name"])      // Neo4jValue.string("Alice")
}
```

---

## Data Types

Responses are decoded using the Neo4j typed JSON format (`application/vnd.neo4j.query.v1.1`), which preserves type information for every value.

| Cypher Type | `Neo4jValue` case | Accessor |
|-------------|-------------------|----------|
| `STRING` | `.string(String)` | `.stringValue` |
| `INTEGER` | `.int(Int)` | `.intValue` |
| `FLOAT` | `.double(Double)` | `.doubleValue` |
| `BOOLEAN` | `.bool(Bool)` | `.boolValue` |
| `NULL` | `.null` | — |
| `DATE` | `.date(String)` | `.dateValue` |
| `NODE` | `.node(Neo4jNode)` | `.nodeValue` |
| `LIST` | `.list([Neo4jValue])` | `.listValue` |
| `MAP` | `.map([String: Neo4jValue])` | `.mapValue` |

---

## Error Handling

`runQuery` throws `SwiftCypherError` on failure:

| Error | Cause |
|-------|-------|
| `.invalidURL` | Malformed host URL |
| `.invalidHTTPResponse` | Non-HTTP response received |
| `.unsuccessfulRequest` | Server returned non-202 status |
| `.jsonDecodingError` | Response body could not be decoded |
| `.missingCredentials` | Required credentials not found in environment |
| `.missingDatabaseName(key:)` | Required database key not found in environment |

---

## License

MIT License — Copyright (c) 2026 Szabolcs Tóth and the SwiftCypher project authors.  
See [LICENSE](LICENSE) for details.
