nonisolated struct DocumentContext: Equatable, Sendable {
    let schoolID: String?
    let childID: String?
    let classID: String?

    init(schoolID: String? = nil, childID: String? = nil, classID: String? = nil) {
        self.schoolID = schoolID
        self.childID = childID
        self.classID = classID
    }
}
