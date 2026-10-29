import Foundation

nonisolated struct APIRequest: Sendable {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryItems: [URLQueryItem]
    let body: Data?

    init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }

    init<Body: Encodable & Sendable>(
        path: String,
        method: HTTPMethod,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        jsonBody body: Body,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        var requestHeaders = headers
        if !requestHeaders.keys.contains(where: { $0.caseInsensitiveCompare("Content-Type") == .orderedSame })
        {
            requestHeaders["Content-Type"] = "application/json"
        }

        do {
            self.path = path
            self.method = method
            self.headers = requestHeaders
            self.queryItems = queryItems
            self.body = try encoder.encode(body)
        } catch let error as EncodingError { throw APIError.encoding(error) }
    }
}
