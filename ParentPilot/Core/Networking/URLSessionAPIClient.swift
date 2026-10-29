import Foundation

nonisolated struct URLSessionAPIClient: APIClient {
    private let configuration: AppConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    init(configuration: AppConfiguration, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder())
    {
        self.configuration = configuration
        self.session = session
        self.decoder = decoder
    }

    func send<Response: Decodable & Sendable>(_ request: APIRequest, as responseType: Response.Type)
        async throws -> Response
    {
        let data = try await perform(request)

        do { return try decoder.decode(responseType, from: data) } catch let error as DecodingError {
            throw APIError.decoding(error)
        }
    }

    func send(_ request: APIRequest) async throws { _ = try await perform(request) }

    private func perform(_ request: APIRequest) async throws -> Data {
        let urlRequest = try makeURLRequest(from: request)

        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: urlRequest) } catch let error as URLError {
            throw APIError.transport(error)
        } catch { throw APIError.transport(URLError(.unknown, userInfo: [NSUnderlyingErrorKey: error])) }

        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.http(statusCode: httpResponse.statusCode, responseBody: data)
        }

        return data
    }

    private func makeURLRequest(from request: APIRequest) throws -> URLRequest {
        guard !request.path.contains("://"),
            var components = URLComponents(
                url: configuration.baseURL.appendingPathComponent(request.path),
                resolvingAgainstBaseURL: false
            )
        else { throw APIError.configuration("The request path must be relative to the configured base URL.") }

        if !request.queryItems.isEmpty { components.queryItems = request.queryItems }

        guard let url = components.url else { throw APIError.configuration("The request URL is invalid.") }

        var urlRequest = URLRequest(url: url, timeoutInterval: configuration.requestTimeout)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        for (name, value) in request.headers { urlRequest.setValue(value, forHTTPHeaderField: name) }
        return urlRequest
    }
}
