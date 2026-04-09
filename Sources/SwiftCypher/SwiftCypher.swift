import Foundation
import Logging

public struct SwiftCypherClient {
   /// `host` is where the Neo4j instance is located (example: localhost, xxx.databases.neo4j.io)
    let host: String
    
    /// `port` is the port on which the Neo4j HTTP server is set to listen on (optional; default 7474),
    let port: Int
    
    /// `databaseName` is the database you want to query (example: neo4j).
    let databaseName: String
    
    
    public init(host: String = "localhost", port: Int = 7474, databaseName: String = "neo4j") {
        self.host = host
        self.port = port
        self.databaseName = databaseName
    }
    
    // MARK: - runs a query
    /// The server wraps the submitted Cypher query in a (implicit) transaction for you.
    /// Each request must include an Authorization header.
    public func runQuery() async throws {
        guard let url = URL(string: "http://\(host):\(port)/db/\(databaseName)/query/v2") else {
            Logger(label: "SwiftCypherClient").error("Invalid URL")
            throw SwiftCypherError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Basic \("neo4j:password".data(using: .utf8)!.base64EncodedString())", forHTTPHeaderField: "Authorization")
        let body = ["statement": "MATCH (n:Person) RETURN n.name"]
        urlRequest.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        print(response)
    }
}

public enum SwiftCypherError: Error {
    case invalidURL
}
