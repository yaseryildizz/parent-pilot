nonisolated protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(_ request: APIRequest, as responseType: Response.Type)
        async throws -> Response

    func send(_ request: APIRequest) async throws
}
