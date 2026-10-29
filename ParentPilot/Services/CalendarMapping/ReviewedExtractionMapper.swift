nonisolated struct ReviewedExtractionMapper: Sendable {
    private let reminderPolicy: ReminderPolicy

    init(reminderPolicy: ReminderPolicy = .init()) { self.reminderPolicy = reminderPolicy }

    func map(_ review: ExtractionReviewResult) -> CalendarMappingResult {
        var output = CalendarMappingResult()
        let rejectedCandidateIDs = Set(review.rejected.map(\.id))

        for candidate in review.accepted {
            if rejectedCandidateIDs.contains(candidate.id) {
                output.skip(candidate, .conflictingReviewDecision)
                continue
            }

            let provenance = CalendarProvenance(
                extractionCandidateID: candidate.id,
                evidence: candidate.evidence
            )

            switch candidate.type {
            case .event, .holiday, .activity:
                guard let temporal = candidate.temporal else {
                    output.skip(candidate, .missingDate)
                    continue
                }
                guard let eventType = eventType(for: candidate.type) else {
                    output.skip(candidate, .unsupportedType)
                    continue
                }
                let id = SchoolEventID(rawValue: "candidate:\(candidate.id)")
                output.events.append(
                    .init(
                        id: id,
                        title: candidate.title,
                        time: temporal.eventTime,
                        type: eventType,
                        recurrence: temporal.recurrence,
                        provenance: provenance,
                        context: .init()
                    )
                )
                output.reminderIntents.append(
                    .init(
                        id: ReminderIntentID(rawValue: "reminder:\(candidate.id)"),
                        target: .event(id),
                        leadTime: reminderPolicy.eventLeadTime,
                        provenance: provenance
                    )
                )
            case .task, .payment, .reminder:
                let id = TaskID(rawValue: "candidate:\(candidate.id)")
                let due = candidate.temporal?.eventTime
                output.tasks.append(
                    .init(id: id, title: candidate.title, due: due, provenance: provenance, context: .init())
                )
                if candidate.type == .payment, due != nil {
                    output.reminderIntents.append(
                        .init(
                            id: ReminderIntentID(rawValue: "reminder:\(candidate.id)"),
                            target: .task(id),
                            leadTime: reminderPolicy.paymentLeadTime,
                            provenance: provenance
                        )
                    )
                }
                if candidate.type == .reminder, due != nil {
                    output.reminderIntents.append(
                        .init(
                            id: ReminderIntentID(rawValue: "reminder:\(candidate.id)"),
                            target: .task(id),
                            leadTime: .zero,
                            provenance: provenance
                        )
                    )
                }
            case .pickupChange:
                guard let temporal = candidate.temporal else {
                    output.skip(candidate, .missingDate)
                    continue
                }
                guard let newTime = temporal.startTime else {
                    output.skip(candidate, .missingTime)
                    continue
                }
                let id = ScheduleOverrideID(rawValue: "override:\(candidate.id)")
                output.overrides.append(
                    .init(
                        id: id,
                        type: .pickupChange,
                        targetDate: temporal.date,
                        affectedEventID: nil,
                        previousTime: nil,
                        newTime: newTime,
                        reason: candidate.details,
                        provenance: provenance,
                        context: .init()
                    )
                )
                output.reminderIntents.append(
                    .init(
                        id: ReminderIntentID(rawValue: "reminder:\(candidate.id)"),
                        target: .scheduleOverride(id),
                        leadTime: reminderPolicy.pickupLeadTime,
                        provenance: provenance
                    )
                )
            case .general: output.skip(candidate, .unsupportedType)
            }
        }
        return output
    }

    private func eventType(for candidateType: ExtractionCandidateType) -> SchoolEventType? {
        switch candidateType {
        case .holiday: .holiday
        case .activity: .activity
        case .event: .event
        case .reminder, .task, .pickupChange, .payment, .general: nil
        }
    }
}

nonisolated extension CalendarMappingResult {
    fileprivate mutating func skip(_ candidate: ExtractionCandidate, _ reason: CalendarMappingSkipReason) {
        skippedCandidates.append(.init(candidateID: candidate.id, reason: reason))
    }
}
