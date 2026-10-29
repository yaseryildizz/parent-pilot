import Foundation
import UniformTypeIdentifiers

nonisolated struct ValidatedDocument: Sendable {
    let filename: String
    let mimeType: String
    let contents: Data
}

nonisolated struct DocumentValidator: Sendable {
    private let maximumUploadBytes: Int64?

    init(maximumUploadBytes: Int64?) { self.maximumUploadBytes = maximumUploadBytes }

    func validate(fileURL: URL) throws -> ValidatedDocument {
        guard fileURL.pathExtension.caseInsensitiveCompare("pdf") == .orderedSame else {
            throw DocumentServiceError.unsupportedDocument
        }

        let resourceValues: URLResourceValues
        do { resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey]) } catch {
            throw DocumentServiceError.fileAccessFailed
        }

        if let contentType = resourceValues.contentType, !contentType.conforms(to: .pdf) {
            throw DocumentServiceError.unsupportedDocument
        }

        if let maximumUploadBytes, let fileSize = resourceValues.fileSize,
            Int64(fileSize) > maximumUploadBytes
        {
            throw DocumentServiceError.fileTooLarge(maximumBytes: maximumUploadBytes)
        }

        do {
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            guard try handle.read(upToCount: 5) == Data("%PDF-".utf8) else {
                throw DocumentServiceError.unsupportedDocument
            }
        } catch let error as DocumentServiceError { throw error } catch {
            throw DocumentServiceError.fileAccessFailed
        }

        do {
            return ValidatedDocument(
                filename: fileURL.lastPathComponent,
                mimeType: UTType.pdf.preferredMIMEType ?? "application/pdf",
                contents: try Data(contentsOf: fileURL, options: .mappedIfSafe)
            )
        } catch { throw DocumentServiceError.fileAccessFailed }
    }
}
