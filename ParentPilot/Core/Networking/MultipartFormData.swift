import Foundation

nonisolated struct MultipartFormData: Sendable {
    let boundary: String
    private var data = Data()

    init(boundary: String = "ParentPilot-\(UUID().uuidString)") { self.boundary = boundary }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func addTextField(name: String, value: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(sanitized(name))\"\r\n\r\n")
        append(value)
        append("\r\n")
    }

    mutating func addFile(name: String, filename: String, mimeType: String, contents: Data) {
        append("--\(boundary)\r\n")
        append(
            "Content-Disposition: form-data; name=\"\(sanitized(name))\"; "
                + "filename=\"\(sanitized(filename))\"\r\n"
        )
        append("Content-Type: \(sanitized(mimeType))\r\n\r\n")
        data.append(contents)
        append("\r\n")
    }

    func encoded() -> Data {
        var encoded = data
        encoded.append(Data("--\(boundary)--\r\n".utf8))
        return encoded
    }

    private mutating func append(_ value: String) { data.append(Data(value.utf8)) }

    private func sanitized(_ value: String) -> String {
        value.replacingOccurrences(of: "\r", with: "_").replacingOccurrences(of: "\n", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
    }
}
