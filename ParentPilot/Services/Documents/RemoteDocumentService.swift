import Foundation

nonisolated struct RemoteDocumentService: DocumentService {
    private let apiClient: any APIClient
    private let validator: DocumentValidator

    init(apiClient: any APIClient, configuration: AppConfiguration) {
        self.apiClient = apiClient
        validator = DocumentValidator(maximumUploadBytes: configuration.maximumDocumentUploadBytes)
    }

    func uploadDocument(at fileURL: URL, metadata: DocumentUploadMetadata) async throws -> SchoolDocument {
        let document = try validator.validate(fileURL: fileURL)
        var multipart = MultipartFormData()
        multipart.addFile(
            name: "file",
            filename: document.filename,
            mimeType: document.mimeType,
            contents: document.contents
        )
        multipart.addTextField(name: "scope", value: metadata.scope.rawValue)
        add(metadata.context.schoolID, named: "schoolID", to: &multipart)
        add(metadata.context.childID, named: "childID", to: &multipart)
        add(metadata.context.classID, named: "classID", to: &multipart)

        let request = APIRequest(
            path: "v1/documents",
            method: .post,
            headers: ["Content-Type": multipart.contentType],
            body: multipart.encoded()
        )

        do {
            let response = try await apiClient.send(request, as: DocumentUploadResponseDTO.self)
            return try DocumentDTOMapper.map(response)
        } catch let error as DocumentServiceError { throw error } catch let error as APIError {
            throw translateUploadError(error)
        } catch { throw DocumentServiceError.uploadFailed }
    }

    func fetchProcessingStatus(documentID: DocumentID) async throws -> DocumentProcessingStatus {
        let request = APIRequest(path: "v1/documents/\(try encoded(documentID))/status")
        do {
            let response = try await apiClient.send(request, as: DocumentProcessingStatusDTO.self)
            guard response.documentID == documentID.rawValue else {
                throw DocumentServiceError.invalidServerResponse
            }
            return try DocumentDTOMapper.map(response)
        } catch let error as DocumentServiceError { throw error } catch let error as APIError {
            throw translateRequestError(error, extractionRequest: false)
        } catch { throw DocumentServiceError.requestFailed }
    }

    func fetchExtractionResult(documentID: DocumentID) async throws -> ExtractionResult {
        let request = APIRequest(path: "v1/documents/\(try encoded(documentID))/extraction")
        do {
            let response = try await apiClient.send(request, as: ExtractionResultDTO.self)
            guard response.documentID == documentID.rawValue else {
                throw DocumentServiceError.invalidServerResponse
            }
            return try DocumentDTOMapper.map(response)
        } catch let error as DocumentServiceError { throw error } catch let error as APIError {
            throw translateRequestError(error, extractionRequest: true)
        } catch { throw DocumentServiceError.requestFailed }
    }

    private func add(_ value: String?, named name: String, to multipart: inout MultipartFormData) {
        guard let value, !value.isEmpty else { return }
        multipart.addTextField(name: name, value: value)
    }

    private func encoded(_ documentID: DocumentID) throws -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        guard !documentID.rawValue.isEmpty,
            let value = documentID.rawValue.addingPercentEncoding(withAllowedCharacters: allowed)
        else { throw DocumentServiceError.invalidServerResponse }
        return value
    }

    private func translateUploadError(_ error: APIError) -> DocumentServiceError {
        switch error {
        case .http(let statusCode, _):
            switch statusCode {
            case 413: .fileTooLarge(maximumBytes: nil)
            case 415: .unsupportedDocument
            default: .uploadFailed
            }
        case .decoding, .invalidResponse, .configuration: .invalidServerResponse
        case .transport, .encoding: .uploadFailed
        }
    }

    private func translateRequestError(_ error: APIError, extractionRequest: Bool) -> DocumentServiceError {
        switch error {
        case .http(let statusCode, _):
            if extractionRequest && (statusCode == 404 || statusCode == 409) { return .extractionUnavailable }
            return statusCode >= 500 ? .processingFailed : .requestFailed
        case .decoding, .invalidResponse, .configuration: return .invalidServerResponse
        case .transport, .encoding: return .requestFailed
        }
    }
}
