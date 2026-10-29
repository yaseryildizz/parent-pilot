nonisolated enum AppEnvironment: String, CaseIterable, Sendable {
    case development
    case staging
    case production

    static var current: AppEnvironment {
        #if DEBUG
            .development
        #else
            .production
        #endif
    }
}
