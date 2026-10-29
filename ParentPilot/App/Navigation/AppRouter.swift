import Observation

@MainActor
@Observable
final class AppRouter {
    private(set) var path: [AppRoute] = []

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func reset() { path.removeAll() }
}
