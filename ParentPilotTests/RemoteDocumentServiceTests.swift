import Foundation
import Testing

@testable import ParentPilot

@Suite(.serialized)
struct RemoteDocumentServiceTests {
    @Test
    func uploadReturnsDomainDocumentAndBuildsMultipartRequest() async throws {
        let response = Data(
            #"{"id":"document-1","originalFilename":"calendar.pdf","uploadedAt":"2026-09-04T10:00:00Z","source":"pdfUpload","scope":"schoolWide","processingStatus":"queued","schoolID":"school-1","childID":null,"classID":null}"#
                .utf8
        )
        let apiClient = DocumentAPIClientStub(result: .success(response))
        let service = RemoteDocumentService(
            apiClient: apiClient,
            configuration: AppConfiguration(environment: .development)
        )
        let fileURL = try makePDF()
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let document = try await service.uploadDocument(
            at: fileURL,
            metadata: DocumentUploadMetadata(
                scope: .schoolWide,
                context: DocumentContext(schoolID: "school-1")
            )
        )

        #expect(document.id == DocumentID(rawValue: "document-1"))
        #expect(document.processingStatus == .queued)
        #expect(document.context.schoolID == "school-1")

        let request = try #require(await apiClient.lastRequest())
        #expect(request.path == "v1/documents")
        #expect(request.method == .post)
        #expect(request.headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        let requestBody = try #require(request.body)
        #expect(requestBody.range(of: Data(fileURL.lastPathComponent.utf8)) != nil)
        #expect(requestBody.range(of: Data("schoolWide".utf8)) != nil)
    }

    @Test
    func translatesUnsupportedMediaType() async throws {
        let apiClient = DocumentAPIClientStub(result: .failure(.http(statusCode: 415, responseBody: Data())))
        let service = RemoteDocumentService(
            apiClient: apiClient,
            configuration: AppConfiguration(environment: .development)
        )
        let fileURL = try makePDF()
        defer { try? FileManager.default.removeItem(at: fileURL) }

        await #expect(throws: DocumentServiceError.unsupportedDocument) {
            _ = try await service.uploadDocument(at: fileURL, metadata: DocumentUploadMetadata())
        }
    }

    private func makePDF() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        try Data("%PDF-test fixture".utf8).write(to: url, options: .atomic)
        return url
    }
}

private actor DocumentAPIClientStub: APIClient {
    private let result: Result<Data, APIError>
    private var requests: [APIRequest] = []

    init(result: Result<Data, APIError>) { self.result = result }

    func send<Response: Decodable & Sendable>(_ request: APIRequest, as responseType: Response.Type)
        async throws -> Response
    {
        requests.append(request)
        let data = try result.get()
        do { return try JSONDecoder().decode(responseType, from: data) } catch let error as DecodingError {
            throw APIError.decoding(error)
        }
    }

    func send(_ request: APIRequest) async throws {
        requests.append(request)
        _ = try result.get()
    }

    func lastRequest() -> APIRequest? { requests.last }
}
