# SwiftCypher

A lightweight, idiomatic Swift wrapper for the [Neo4j Query API](https://neo4j.com/docs/query-api/current/) (v2). Execute Cypher queries over HTTPS from any Swift platform — iOS, macOS, Linux, or serverless — with no Bolt driver required.

---

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| macOS    | 15.0+          |
| iOS      | 18.0+          |

**Neo4j:** 5.19+ (Query API v2)  
**Swift:** 6.0+ (strict concurrency enabled)

---

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftCypher", from: "0.0.1")
]
```

Or via Xcode: **File → Add Package Dependencies** and paste the repository URL.

---

## Quick Start

```swift
import Configuration
import SwiftCypher

// Credentials come from environment variables or a .env file using Swift Configuration
let username = reader.string(forKey: "USERNAME") ?? "neo4j"
let password = reader.string(forKey: "PASSWORD") ?? "neo4j"

let client = SwiftCypherClient(username: username, password: password)
let request = QueryRequest(statement: "MATCH (n:Person) RETURN n.name")
let response = try await client.runQuery(request: request)

for row in response.rows {
    print(row["n.name"]?.stringValue ?? "")
}
```

---

## Connecting to Neo4j

Credentials are read from environment variables or a `.env` file — never hardcoded.

### Local instance (default)

```swift
let username = reader.string(forKey: "USERNAME") ?? "neo4j"
let password = reader.string(forKey: "PASSWORD") ?? "neo4j"

let client = SwiftCypherClient(username: username, password: password)
// Connects to http://localhost:7474/db/neo4j/query/v2
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
guard let db       = reader.string(forKey: "NEO4J_DATABASE"),
      let username = reader.string(forKey: "NEO4J_USERNAME"),
      let password = reader.string(forKey: "NEO4J_PASSWORD")
else { throw SwiftCypherError.missingCredentials }

let client = SwiftCypherClient(
    service: .aura(database: db),
    username: username,
    password: password
)
// Connects to https://<database>.databases.neo4j.io/db/<database>/query/v2
```

### `.env` file format

```
# Local
USERNAME=neo4j
PASSWORD=yourpassword

# Aura
NEO4J_DATABASE=your-aura-instance
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your-aura-password
```

The `Service` enum builds the correct URL for each environment:

| Case | URL |
|------|-----|
| `.localhost(database:)` | `http://localhost:7474/db/{database}/query/v2` |
| `.aura(database:)` | `https://{database}.databases.neo4j.io/db/{database}/query/v2` |

---

## Running Queries

### Without parameters

```swift
let request = QueryRequest(statement: "MATCH (n:Person) RETURN n.name, n.age")
let response = try await client.runQuery(request: request)
```

### With parameters (always prefer this)

Always use parameterized queries instead of string interpolation — this prevents Cypher injection and improves server-side query plan caching.

```swift
let request = QueryRequest(
    statement: "MERGE (n:Person {name: $name, age: $age}) RETURN n",
    parameters: ["name": "Alice", "age": 30]
)
```

`Neo4jValue` conforms to Swift's literal protocols, so you can pass plain Swift literals directly in the parameters dictionary.

### Create nodes

```swift
let request = QueryRequest(
    statement: "CREATE (n:Person {name: $name}) RETURN n",
    parameters: ["name": "Szabolcs"]
)
let response = try await client.runQuery(request: request)
```

---

## Working with Results

`QueryResponse` exposes three properties:

| Property | Type | Description |
|----------|------|-------------|
| `rows` | `[[String: Neo4jValue]]` | Results as field-keyed dictionaries |
| `fields` | `[String]` | Column names from the `RETURN` clause |
| `bookmarks` | `[String]` | Opaque tokens for causal consistency |

### Accessing row values

```swift
for row in response.rows {
    let name  = row["n.name"]?.stringValue   // String?
    let age   = row["n.age"]?.intValue       // Int?
    let score = row["n.score"]?.doubleValue  // Double?
    let active = row["n.active"]?.boolValue  // Bool?
    let node  = row["n"]?.nodeValue          // Neo4jNode?
}
```

### Accessing node properties

```swift
if let node = row["n"]?.nodeValue {
    print(node.elementId)              // "4:abc123:0"
    print(node.labels)                 // ["Person"]
    print(node.properties["name"])     // Neo4jValue.string("Alice")
}
```

---

## Data Types

`Neo4jValue` maps all Cypher types to Swift:

| Cypher Type | Neo4jValue case | Accessor |
|------------|----------------|----------|
| `STRING` | `.string(String)` | `.stringValue` |
| `INTEGER` | `.int(Int)` | `.intValue` |
| `FLOAT` | `.double(Double)` | `.doubleValue` |
| `BOOLEAN` | `.bool(Bool)` | `.boolValue` |
| `NULL` | `.null` | — |
| `NODE` | `.node(Neo4jNode)` | `.nodeValue` |
| `LIST` | `.list([Neo4jValue])` | `.listValue` |
| `MAP` | `.map([String: Neo4jValue])` | `.mapValue` |

`Neo4jValue` also conforms to Swift's literal protocols so you can write:

```swift
let params: [String: Neo4jValue] = [
    "name":   "Alice",   // ExpressibleByStringLiteral
    "age":    30,        // ExpressibleByIntegerLiteral
    "score":  98.5,      // ExpressibleByFloatLiteral
    "active": true       // ExpressibleByBooleanLiteral
]
```

---

## License

MIT License

Copyright (c) 2026 Szabolcs Tóth and the SwiftCypher project authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
