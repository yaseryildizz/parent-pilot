import Foundation
import Testing

@testable import ParentPilot

struct MultipartFormDataTests {
    @Test
    func constructsPDFPartAndMetadataFields() throws {
        var multipart = MultipartFormData(boundary: "test-boundary")
        multipart.addFile(
            name: "file",
            filename: "calendar.pdf",
            mimeType: "application/pdf",
            contents: Data("%PDF-test".utf8)
        )
        multipart.addTextField(name: "scope", value: "schoolWide")
        multipart.addTextField(name: "schoolID", value: "school-1")

        let body = try #require(String(data: multipart.encoded(), encoding: .utf8))

        #expect(multipart.contentType == "multipart/form-data; boundary=test-boundary")
        #expect(body.contains("name=\"file\"; filename=\"calendar.pdf\""))
        #expect(body.contains("Content-Type: application/pdf"))
        #expect(body.contains("%PDF-test"))
        #expect(body.contains("name=\"scope\"\r\n\r\nschoolWide"))
        #expect(body.contains("name=\"schoolID\"\r\n\r\nschool-1"))
        #expect(body.hasSuffix("--test-boundary--\r\n"))
    }
}
