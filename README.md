# SwiftCypher
![Swift 6.3](https://img.shields.io/badge/Swift-6.3-orange.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue.svg)
![MIT License](https://img.shields.io/badge/license-MIT-green.svg)

A lightweight, idiomatic Swift client for the [Neo4j Query API](https://neo4j.com/docs/query-api/current/) (v2). Execute Cypher queries over HTTPS from any Swift platform — iOS, macOS, or Linux — with no Bolt driver required.

---

## Features

- Async/await API built on `URLSession`
- Supports local Neo4j instances and [Aura](https://neo4j.com/cloud/platform/aura-graph-database/) (cloud)
- Basic and Bearer token authentication
- Typed response values: `String`, `Integer`, `Float`, `Boolean`, `Date`, `Node`, `List`, `Map`
- Typed JSON responses via `application/vnd.neo4j.query` — no ambiguous types
- Parameterized queries to prevent Cypher injection and improve query plan caching
- Automatic reconnection and query retry on transient failures

---

## Requirements

| Platform | Minimum |
|----------|---------|
| macOS    | 15.0+   |
| iOS      | 18.0+   |

- **Neo4j:** 5.19+ (Query API v2)
- **Swift:** 6.3+

---

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kicsipixel/SwiftCypher", from: "0.4.1")
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

let client = try await SwiftCypherClient.connect(
    credential: .basic(username: "neo4j", password: "yourpassword")
)
let request = QueryRequest(statement: "MATCH (n:Person) RETURN n.name")
let response = try await client.runQuery(request: request)

for row in response {
    print(row["n.name"]?.stringValue ?? "")
}
```

---

## Connecting to Neo4j

`SwiftCypherClient.connect(...)` creates a verified client. Before returning, it pings Neo4j and retries up to 10 times with 1-second intervals — useful when starting alongside a Neo4j container. Call `ping()` on an existing client to re-check the connection at any time.

### Authentication

SwiftCypher supports two authentication methods via the `Credential` type:

**Basic auth** (username + password) — works with any Neo4j instance out of the box:

```swift
let client = try await SwiftCypherClient.connect(
    credential: .basic(username: username, password: password)
)
```

**Bearer token** — for Neo4j instances configured with an SSO/OIDC provider (Okta, Microsoft Entra ID, Google). Your application obtains the JWT from the identity provider and passes it here:

```swift
let client = try await SwiftCypherClient.connect(
    service: .aura(database: db),
    credential: .bearer(token: jwtToken)
)
```

> Never hardcode credentials. Read them from environment variables or a `.env` file using [swift-configuration](https://github.com/apple/swift-configuration), which ships as a transitive dependency of SwiftCypher.

### Local instance (default database)

```swift
let client = try await SwiftCypherClient.connect(
    credential: .basic(username: username, password: password)
)
// → http://localhost:7474/db/neo4j/query/v2
```

### Local instance with a custom database

```swift
let client = try await SwiftCypherClient.connect(
    service: .localhost(database: "mydb"),
    credential: .basic(username: username, password: password)
)
```

### Neo4j Aura (cloud)

```swift
let client = try await SwiftCypherClient.connect(
    service: .aura(database: db),
    credential: .basic(username: username, password: password)
)
// → https://<db>.databases.neo4j.io/db/<db>/query/v2
```

### Service endpoints

| Case | URL |
|------|-----|
| `.localhost(database:)` | `http://localhost:7474/db/{database}/query/v2` |
| `.aura(database:)` | `https://{database}.databases.neo4j.io/db/{database}/query/v2` |

### Example `.env` file

```
# Local Neo4j
USERNAME=neo4j
PASSWORD=yourpassword
# DATABASE=neo4j  ← optional; defaults to "neo4j"

# Neo4j Aura
AURA_DATABASE=<instance-id>   # found in the Aura connection URI
AURA_USERNAME=neo4j
AURA_PASSWORD=<your-aura-password>
```

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

Pass dates as `.date("yyyy-MM-dd")`. This sends a typed Neo4j `Date` value — no `date()` wrapper is needed in the Cypher statement:

```swift
let request = QueryRequest(
    statement: """
        CREATE (e:Event {
            name: $name,
            start_date: $startDate,
            end_date: $endDate
        })
        """,
    parameters: [
        "name": .string("Skiing in Tirol"),
        "startDate": .date("2026-02-01"),
        "endDate": .date("2026-02-03"),
    ]
)
```

Reading a `Date` property back from a node uses `.dateValue`, which returns the ISO 8601 string:

```swift
let dateString = node.properties["start_date"]?.dateValue  // "2026-02-01"
```

---

## Working with Results

`QueryResponse` conforms to `Sequence` and yields `[String: Neo4jValue]` rows, so you can iterate it directly or use `.rows` explicitly:

| Property | Type | Description |
|----------|------|-------------|
| `rows` | `[[String: Neo4jValue]]` | Results keyed by field name from the `RETURN` clause |
| `fields` | `[String]` | Column names from the `RETURN` clause |
| `bookmarks` | `[String]` | Opaque tokens for causal consistency chaining |
| `counters` | `QueryCounters?` | Write statistics (nodes/relationships created or deleted, properties set, labels added/removed) |

```swift
for row in response {
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

### Write statistics

Neo4j silently ignores write operations that match nothing (e.g. deleting a non-existent node). Use `QueryCounters` to confirm that a write actually had an effect.

`counters` is populated when `includeCounters` is `true` (the default) on the `QueryRequest`:

```swift
let request = QueryRequest(
    statement: "CREATE (n:Person {name: $name})",
    parameters: ["name": .string("Alice")]
)
let response = try await client.runQuery(request: request)

if let counters = response.counters {
    print(counters.nodesCreated)         // 1
    print(counters.propertiesSet)        // 1
    print(counters.relationshipsCreated) // 0
}
```

Pass `includeCounters: false` to omit them when you don't need them:

```swift
let request = QueryRequest(
    statement: "MATCH (n:Person) RETURN n.name",
    includeCounters: false
)
```

---

## Data Types

Responses are decoded using the Neo4j typed JSON format (`application/vnd.neo4j.query`), which preserves type information for every value.

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

## Run Queries as a Different User

SwiftCypher supports Neo4j impersonation — executing a query within the security context of a different user while authenticating as an admin. This is useful for enforcing fine-grained access control without managing separate connections per user.

> **Requirements:** Neo4j Enterprise. The authenticated user must have `GRANT IMPERSONATE` privilege. Not available on Community Edition.

### Usage

Pass `impersonatedUser` to `QueryRequest`. The client still authenticates as your admin, but the query runs as the specified user:

```swift
// Runs as "alice" — read-only, cannot write
let request = QueryRequest(
    statement: "MATCH (n:Person) RETURN n.name",
    impersonatedUser: "alice"
)
let response = try await client.runQuery(request: request)
```

If the impersonated user lacks permission for the operation, Neo4j returns a `400` with `Neo.ClientError.Security.Forbidden` and a description of what was denied. SwiftCypher surfaces this as `SwiftCypherError.clientError` with the `neo4jCode` and `message` fields populated.

---

## Error Handling

`runQuery` throws `SwiftCypherError` on failure. Non-4xx errors trigger an automatic reconnect and one retry before the error is surfaced.

| Error | Cause |
|-------|-------|
| `.clientError(statusCode:neo4jCode:message:)` | Neo4j returned a 4xx — includes the Neo4j error code and message when available |
| `.invalidURL` | Malformed host URL |
| `.invalidHTTPResponse` | Non-HTTP response received |
| `.unsuccessfulRequest` | Server returned a non-202, non-4xx status |
| `.jsonDecodingError` | Response body could not be decoded |
| `.missingCredentials` | Credentials not found (for use with `ConfigReader` integration) |
| `.missingDatabaseName(key:)` | Database name not found under the given environment key |

---

## License

MIT License — Copyright (c) 2026 Szabolcs Tóth and the SwiftCypher project authors.  
See [LICENSE](LICENSE) for details.
