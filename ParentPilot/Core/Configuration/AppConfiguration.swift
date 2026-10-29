import Foundation

nonisolated struct AppConfiguration: Sendable {
    let environment: AppEnvironment
    let baseURL: URL
    let requestTimeout: TimeInterval
    /// Client-side optimization only. The backend remains authoritative.
    let maximumDocumentUploadBytes: Int64?

    init(environment: AppEnvironment) {
        self.environment = environment
        requestTimeout = 30
        maximumDocumentUploadBytes = nil

        switch environment {
        case .development: baseURL = Self.developmentBaseURL()
        case .staging:
            // Reserved placeholder. Replace through an approved environment configuration.
            baseURL = Self.url("https://staging.parentpilot.invalid")
        case .production:
            // Reserved placeholder. This is deliberately not a deployable backend URL.
            baseURL = Self.url("https://parentpilot.invalid")
        }
    }

    private static func url(_ value: String) -> URL {
        guard let url = URL(string: value) else { preconditionFailure("Invalid built-in application URL") }
        return url
    }

    private static func developmentBaseURL() -> URL {
        #if DEBUG
            let override = ProcessInfo.processInfo.environment["PARENTPILOT_API_BASE_URL"]
            if let override, let url = URL(string: override), isSupportedDevelopmentURL(url) { return url }
        #endif

        return Self.url("http://127.0.0.1:8080")
    }

    private static func isSupportedDevelopmentURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
            let host = url.host, !host.isEmpty
        else { return false }
        return true
    }
}
