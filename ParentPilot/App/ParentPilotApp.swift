import SwiftUI

@main
struct ParentPilotApp: App {
    private let dependencies: AppDependencies
    @State
    private var documentsViewModel: DocumentsViewModel

    init() { self.init(environment: .current) }

    init(environment: AppEnvironment) {
        let dependencies = AppDependencies(environment: environment)
        self.dependencies = dependencies
        _documentsViewModel = State(
            initialValue: DocumentsViewModel(
                documentService: dependencies.documentService,
                documentValidator: dependencies.documentValidator,
                processingMonitor: DocumentProcessingMonitor(documentService: dependencies.documentService)
            )
        )
    }

    var body: some Scene { WindowGroup { ContentView(viewModel: documentsViewModel) } }
}
