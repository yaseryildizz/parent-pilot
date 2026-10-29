import Foundation

nonisolated enum APIError: Error, Sendable {
    case configuration(String)
    case transport(URLError)
    case invalidResponse
    case http(statusCode: Int, responseBody: Data)
    case encoding(EncodingError)
    case decoding(DecodingError)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .configuration: "The request could not be configured."
        case .transport: "The server could not be reached."
        case .invalidResponse: "The server returned an invalid response."
        case .http(let statusCode, _): "The server returned HTTP status \(statusCode)."
        case .encoding: "The request body could not be encoded."
        case .decoding: "The server response could not be decoded."
        }
    }
}
