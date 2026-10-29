import Foundation
import Testing

@testable import ParentPilot

@Suite(.serialized)
@MainActor
struct URLSessionAPIClientTests {
    @Test
    func decodesSuccessfulResponseAndBuildsRequest() async throws {
        let client = makeClient { request in
            #expect(request.url?.path == "/items")
            #expect(request.url?.query == "page=2")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "X-Request-ID") == "request-1")

            guard let url = request.url,
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            else { throw URLError(.badServerResponse) }
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }

        let body = RequestBody(name: "document")
        let request = try APIRequest(
            path: "items",
            method: .post,
            headers: ["X-Request-ID": "request-1"],
            queryItems: [URLQueryItem(name: "page", value: "2")],
            jsonBody: body
        )

        let result = try await client.send(request, as: TestResponse.self)

        #expect(result == TestResponse(value: "ok"))
    }

    @Test
    func acceptsSuccessfulResponseWithoutBody() async throws {
        let client = makeClient { request in
            guard let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)
            else { throw URLError(.badServerResponse) }
            return (response, Data())
        }

        try await client.send(APIRequest(path: "items/1", method: .delete))
    }

    @Test
    func throwsHTTPErrorForNonSuccessStatus() async throws {
        let client = makeClient { request in
            guard let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: 422, httpVersion: nil, headerFields: nil)
            else { throw URLError(.badServerResponse) }
            return (response, Data("invalid".utf8))
        }

        do {
            try await client.send(APIRequest(path: "items"))
            Issue.record("Expected an HTTP error")
        } catch let APIError.http(statusCode, responseBody) {
            #expect(statusCode == 422)
            #expect(responseBody == Data("invalid".utf8))
        } catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test
    func throwsDecodingErrorForInvalidPayload() async throws {
        let client = makeClient { request in
            guard let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            else { throw URLError(.badServerResponse) }
            return (response, Data(#"{"unexpected":true}"#.utf8))
        }

        do {
            _ = try await client.send(APIRequest(path: "items"), as: TestResponse.self)
            Issue.record("Expected a decoding error")
        } catch APIError.decoding {
            // Expected.
        } catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test
    func wrapsTransportFailure() async throws {
        let client = makeClient { _ in throw URLError(.notConnectedToInternet) }

        do {
            try await client.send(APIRequest(path: "items"))
            Issue.record("Expected a transport error")
        } catch let APIError.transport(error) { #expect(error.code == .notConnectedToInternet) } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func makeClient(handler: @escaping URLProtocolStub.Handler) -> URLSessionAPIClient {
        URLProtocolStub.handler = handler

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: sessionConfiguration)

        return URLSessionAPIClient(
            configuration: AppConfiguration(environment: .development),
            session: session
        )
    }
}

private struct RequestBody: Encodable, Sendable { let name: String }

private struct TestResponse: Decodable, Equatable, Sendable { let value: String }

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) static var handler: Handler?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }

    override func stopLoading() {}
}
