nonisolated struct ReminderPolicy: Sendable {
    let pickupLeadTime: Duration
    let paymentLeadTime: Duration
    let eventLeadTime: Duration

    init(
        pickupLeadTime: Duration = .seconds(900),
        paymentLeadTime: Duration = .seconds(86_400),
        eventLeadTime: Duration = .seconds(43_200)
    ) {
        self.pickupLeadTime = pickupLeadTime
        self.paymentLeadTime = paymentLeadTime
        self.eventLeadTime = eventLeadTime
    }
}
