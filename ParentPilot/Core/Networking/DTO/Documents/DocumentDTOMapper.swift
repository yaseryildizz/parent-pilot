import Foundation

nonisolated enum DocumentDTOMapper {
    static func map(_ dto: DocumentUploadResponseDTO) throws -> SchoolDocument {
        guard !dto.id.isEmpty, !dto.originalFilename.isEmpty, let uploadedAt = parseDate(dto.uploadedAt),
            let source = DocumentSource(rawValue: dto.source), let scope = DocumentScope(rawValue: dto.scope)
        else { throw DocumentServiceError.invalidServerResponse }

        return SchoolDocument(
            id: DocumentID(rawValue: dto.id),
            originalFilename: dto.originalFilename,
            uploadedAt: uploadedAt,
            source: source,
            scope: scope,
            processingStatus: try mapStatus(dto.processingStatus),
            context: DocumentContext(schoolID: dto.schoolID, childID: dto.childID, classID: dto.classID)
        )
    }

    static func map(_ dto: DocumentProcessingStatusDTO) throws -> DocumentProcessingStatus {
        guard !dto.documentID.isEmpty else { throw DocumentServiceError.invalidServerResponse }
        return try mapStatus(dto.status)
    }

    static func map(_ dto: ExtractionResultDTO) throws -> ExtractionResult {
        guard !dto.documentID.isEmpty, !dto.schemaVersion.isEmpty,
            let generatedAt = parseDate(dto.generatedAt), let origin = ExtractionOrigin(rawValue: dto.origin)
        else { throw DocumentServiceError.invalidServerResponse }

        return ExtractionResult(
            documentID: DocumentID(rawValue: dto.documentID),
            schemaVersion: dto.schemaVersion,
            generatedAt: generatedAt,
            origin: origin,
            candidates: try dto.candidates.map(mapCandidate)
        )
    }

    private static func mapCandidate(_ dto: ExtractionCandidateDTO) throws -> ExtractionCandidate {
        guard let type = ExtractionCandidateType(rawValue: dto.type) else {
            throw DocumentServiceError.invalidServerResponse
        }

        do {
            return try ExtractionCandidate(
                id: dto.id,
                type: type,
                title: dto.title,
                details: dto.details,
                startsAt: try dto.startsAt.map(requiredDate),
                endsAt: try dto.endsAt.map(requiredDate),
                isAllDay: dto.isAllDay,
                confidence: try ExtractionConfidence(score: dto.confidence),
                evidence: try dto.evidence.map(mapEvidence),
                isConflict: dto.isConflict ?? false,
                isScheduleOverride: dto.isScheduleOverride ?? false,
                temporal: try dto.temporal.map(mapTemporal)
            )
        } catch is DocumentModelError { throw DocumentServiceError.invalidServerResponse }
    }

    private static func mapTemporal(_ dto: ExtractedTemporalInfoDTO) throws -> ExtractedTemporalInfo {
        let recurrence: EventRecurrence?
        if let values = dto.recurrenceWeekdays {
            let days = values.compactMap(SchoolWeekday.init(rawValue:))
            guard days.count == values.count else { throw DocumentServiceError.invalidServerResponse }
            recurrence = EventRecurrence(
                weekdays: Set(days),
                startDate: try calendarDate(from: dto.date),
                endDate: try dto.recurrenceEndDate.map { try calendarDate(from: $0) },
                exceptions: []
            )
        } else {
            recurrence = nil
        }

        return try ExtractedTemporalInfo(
            date: calendarDate(from: dto.date),
            startTime: try dto.startTime.map { try localTime(from: $0) },
            endTime: try dto.endTime.map { try localTime(from: $0) },
            timeZoneIdentifier: dto.timeZoneIdentifier,
            recurrence: recurrence
        )
    }

    private static func mapEvidence(_ dto: SourceEvidenceDTO) throws -> SourceEvidence {
        let range: Range<Int>?
        switch (dto.characterStart, dto.characterEnd) {
        case (nil, nil): range = nil
        case (let start?, let end?) where start < end: range = start..<end
        default: throw DocumentServiceError.invalidServerResponse
        }

        do {
            return try SourceEvidence(
                sourceDocumentID: DocumentID(rawValue: dto.sourceDocumentID),
                excerpt: dto.excerpt,
                pageNumber: dto.pageNumber,
                characterRange: range
            )
        } catch is DocumentModelError { throw DocumentServiceError.invalidServerResponse }
    }

    private static func mapStatus(_ value: String) throws -> DocumentProcessingStatus {
        guard let status = DocumentProcessingStatus(rawValue: value) else {
            throw DocumentServiceError.invalidServerResponse
        }
        return status
    }

    private static func requiredDate(_ value: String) throws -> Date {
        guard let date = parseDate(value) else { throw DocumentServiceError.invalidServerResponse }
        return date
    }

    private static func calendarDate(from value: String) throws -> CalendarDate {
        let components = value.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { throw DocumentServiceError.invalidServerResponse }
        return try CalendarDate(year: components[0], month: components[1], day: components[2])
    }

    private static func localTime(from value: String) throws -> LocalTime {
        let components = value.split(separator: ":").compactMap { Int($0) }
        guard components.count >= 2 else { throw DocumentServiceError.invalidServerResponse }
        return try LocalTime(hour: components[0], minute: components[1])
    }

    private static func parseDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        return ISO8601DateFormatter().date(from: value)
    }
}
