struct AppDependencies {
    private let configuration: AppConfiguration
    private let apiClient: any APIClient

    let documentService: any DocumentService
    let documentValidator: DocumentValidator
    let calendarStore: any CalendarStore

    init(environment: AppEnvironment) {
        let configuration = AppConfiguration(environment: environment)
        self.configuration = configuration
        let apiClient = URLSessionAPIClient(configuration: configuration)
        self.apiClient = apiClient
        documentService = RemoteDocumentService(
            apiClient: apiClient,
            configuration: configuration
        )
        documentValidator = DocumentValidator(maximumUploadBytes: configuration.maximumDocumentUploadBytes)
        calendarStore = InMemoryCalendarStore()
    }
}
