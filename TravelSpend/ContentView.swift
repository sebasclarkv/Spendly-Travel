import Combine
import SwiftUI

// MARK: - Visual system

struct TravelSpendBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.22),
                Color.teal.opacity(0.16),
                Color(.systemBackground),
                Color.orange.opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct SpendlyLogoView: View {
    var body: some View {
        Text(L10n.text("app.name"))
            .overlay(alignment: .trailing) {
                SpendlyRouteMark()
                    .frame(width: 21, height: 26)
                    .offset(x: 3, y: 3)
            }
        .font(.system(size: 27, weight: .black, design: .rounded))
        .foregroundStyle(
            LinearGradient(
                colors: [.primary, .blue, .teal],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .accessibilityLabel(L10n.text("app.name"))
    }
}

private struct SpendlyRouteMark: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 2, y: 7))
                path.addCurve(
                    to: CGPoint(x: 17, y: 21),
                    control1: CGPoint(x: 9, y: 8),
                    control2: CGPoint(x: 9, y: 20)
                )
            }
            .trim(from: 0.42, to: 1)
            .stroke(
                .teal,
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [2.2, 3])
            )
            .opacity(0.9)

            Image(systemName: "paperplane.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.teal)
                .rotationEffect(.degrees(36))
                .offset(x: 7, y: 8)
        }
    }
}

extension View {
    @ViewBuilder
    func travelGlassPanel(
        cornerRadius: CGFloat = 22,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
            } else {
                self.glassEffect(.regular.interactive(interactive), in: shape)
            }
        } else {
            self
                .background(.thinMaterial, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 18, y: 10)
        }
    }

    func travelListSurface() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(TravelSpendBackground())
    }
}

// MARK: - Models

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case food
    case transportation
    case lodging
    case flights
    case shopping
    case entertainment
    case emergency
    case other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .food: L10n.text("category.food")
        case .transportation: L10n.text("category.transportation")
        case .lodging: L10n.text("category.lodging")
        case .flights: L10n.text("category.flights")
        case .shopping: L10n.text("category.shopping")
        case .entertainment: L10n.text("category.entertainment")
        case .emergency: L10n.text("category.emergency")
        case .other: L10n.text("category.other")
        }
    }

    var icon: String {
        switch self {
        case .food: "fork.knife"
        case .transportation: "car.fill"
        case .lodging: "bed.double.fill"
        case .flights: "airplane"
        case .shopping: "bag.fill"
        case .entertainment: "ticket.fill"
        case .emergency: "cross.case.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: .orange
        case .transportation: .blue
        case .lodging: .indigo
        case .flights: .cyan
        case .shopping: .pink
        case .entertainment: .purple
        case .emergency: .red
        case .other: .gray
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        if let category = ExpenseCategory(rawValue: rawValue) {
            self = category
            return
        }

        switch rawValue {
        case "accommodation":
            self = .lodging
        case "transport":
            self = .transportation
        case "activities":
            self = .entertainment
        case "health":
            self = .emergency
        default:
            self = .other
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum PaymentMethod: String, CaseIterable, Codable, Identifiable {
    case cash
    case debitCard
    case creditCard
    case bankTransfer
    case digitalWallet
    case other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .cash: L10n.text("payment.cash")
        case .debitCard: L10n.text("payment.debit_card")
        case .creditCard: L10n.text("payment.credit_card")
        case .bankTransfer: L10n.text("payment.bank_transfer")
        case .digitalWallet: L10n.text("payment.digital_wallet")
        case .other: L10n.text("payment.other")
        }
    }

    var icon: String {
        switch self {
        case .cash: "banknote"
        case .debitCard, .creditCard: "creditcard"
        case .bankTransfer: "building.columns"
        case .digitalWallet: "wallet.pass"
        case .other: "questionmark.circle"
        }
    }
}

struct Expense: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Decimal
    var originalAmount: Decimal
    var originalCurrencyCode: String
    var convertedAmount: Decimal
    var category: ExpenseCategory
    var date: Date
    var note: String
    var paymentMethod: PaymentMethod

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        category: ExpenseCategory,
        date: Date,
        note: String = "",
        originalAmount: Decimal? = nil,
        originalCurrencyCode: String = "MXN",
        convertedAmount: Decimal? = nil,
        paymentMethod: PaymentMethod = .creditCard
    ) {
        let baseAmount = convertedAmount ?? amount
        self.id = id
        self.title = title
        self.amount = baseAmount
        self.originalAmount = originalAmount ?? amount
        self.originalCurrencyCode = originalCurrencyCode
        self.convertedAmount = baseAmount
        self.category = category
        self.date = date
        self.note = note
        self.paymentMethod = paymentMethod
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case originalAmount
        case originalCurrencyCode
        case convertedAmount
        case category
        case date
        case note
        case paymentMethod
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Decimal.self, forKey: .amount)
        originalAmount = try container.decodeIfPresent(Decimal.self, forKey: .originalAmount) ?? amount
        originalCurrencyCode = try container.decodeIfPresent(String.self, forKey: .originalCurrencyCode) ?? "MXN"
        convertedAmount = try container.decodeIfPresent(Decimal.self, forKey: .convertedAmount) ?? amount
        category = try container.decode(ExpenseCategory.self, forKey: .category)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        paymentMethod = try container.decodeIfPresent(PaymentMethod.self, forKey: .paymentMethod) ?? .creditCard
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(originalAmount, forKey: .originalAmount)
        try container.encode(originalCurrencyCode, forKey: .originalCurrencyCode)
        try container.encode(convertedAmount, forKey: .convertedAmount)
        try container.encode(category, forKey: .category)
        try container.encode(date, forKey: .date)
        try container.encode(note, forKey: .note)
        try container.encode(paymentMethod, forKey: .paymentMethod)
    }
}

struct ItineraryItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var location: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        location: String = "",
        startDate: Date,
        endDate: Date,
        notes: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.isCompleted = isCompleted
    }
}

struct Trip: Identifiable, Codable, Equatable {
    var id: UUID
    var destination: String
    var budget: Decimal
    var currencyCode: String
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var isClosed: Bool
    var expenses: [Expense]
    var categoryBudgets: [String: Decimal]
    var exchangeRates: [String: Decimal]
    var itineraryItems: [ItineraryItem]

    init(
        id: UUID = UUID(),
        destination: String,
        budget: Decimal,
        currencyCode: String,
        startDate: Date,
        endDate: Date,
        createdAt: Date = Date(),
        isClosed: Bool = false,
        expenses: [Expense] = [],
        categoryBudgets: [String: Decimal] = [:],
        exchangeRates: [String: Decimal]? = nil,
        itineraryItems: [ItineraryItem] = []
    ) {
        self.id = id
        self.destination = destination
        self.budget = budget
        self.currencyCode = currencyCode
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.isClosed = isClosed
        self.expenses = expenses
        self.categoryBudgets = categoryBudgets
        self.exchangeRates = exchangeRates ?? ExchangeRateTable.defaults(for: currencyCode)
        self.itineraryItems = itineraryItems
    }

    var totalSpent: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.convertedAmount }
    }

    var remaining: Decimal {
        budget - totalSpent
    }

    var isOverBudget: Bool {
        totalSpent > budget
    }

    var budgetProgress: Double {
        guard budget > 0 else { return 0 }

        let result = NSDecimalNumber(decimal: totalSpent)
            .dividing(by: NSDecimalNumber(decimal: budget))
            .doubleValue

        return min(max(result, 0), 1)
    }

    var budgetUsedPercent: Double {
        budgetProgress * 100
    }

    func total(for category: ExpenseCategory) -> Decimal {
        expenses
            .filter { $0.category == category }
            .reduce(Decimal.zero) { $0 + $1.convertedAmount }
    }

    func rate(for currencyCode: String) -> Decimal {
        if currencyCode == self.currencyCode {
            return 1
        }

        return exchangeRates[currencyCode] ?? ExchangeRateTable.defaultRate(from: currencyCode, to: self.currencyCode)
    }

    func convertedAmount(for originalAmount: Decimal, currencyCode: String) -> Decimal {
        originalAmount * rate(for: currencyCode)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case destination
        case budget
        case currencyCode
        case startDate
        case endDate
        case createdAt
        case isClosed
        case expenses
        case categoryBudgets
        case exchangeRates
        case itineraryItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        destination = try container.decode(String.self, forKey: .destination)
        budget = try container.decode(Decimal.self, forKey: .budget)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isClosed = try container.decode(Bool.self, forKey: .isClosed)
        expenses = try container.decodeIfPresent([Expense].self, forKey: .expenses) ?? []
        categoryBudgets = try container.decodeIfPresent(
            [String: Decimal].self,
            forKey: .categoryBudgets
        ) ?? [:]
        exchangeRates = try container.decodeIfPresent(
            [String: Decimal].self,
            forKey: .exchangeRates
        ) ?? ExchangeRateTable.defaults(for: currencyCode)
        itineraryItems = try container.decodeIfPresent(
            [ItineraryItem].self,
            forKey: .itineraryItems
        ) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(destination, forKey: .destination)
        try container.encode(budget, forKey: .budget)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isClosed, forKey: .isClosed)
        try container.encode(expenses, forKey: .expenses)
        try container.encode(categoryBudgets, forKey: .categoryBudgets)
        try container.encode(exchangeRates, forKey: .exchangeRates)
        try container.encode(itineraryItems, forKey: .itineraryItems)
    }
}

// MARK: - Formatting and rates

enum MoneyFormatter {
    nonisolated static func string(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
        formatter.minimumFractionDigits = currencyCode == "JPY" ? 0 : 2
        formatter.maximumFractionDigits = currencyCode == "JPY" ? 0 : 2

        return formatter.string(from: NSDecimalNumber(decimal: amount))
            ?? "\(amount) \(currencyCode)"
    }

    nonisolated static func decimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    nonisolated static func editableString(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }
}

enum ExchangeRateTable {
    static let supportedCurrencies = [
        "USD", "EUR", "MXN", "COP", "ARS",
        "CLP", "PEN", "BRL", "UYU", "DOP",
        "CRC", "GTQ", "GBP", "CAD", "JPY",
        "CNY", "KRW", "CHF", "AUD", "THB"
    ]

    private static let usdRates: [String: Decimal] = [
        "USD": 1,
        "EUR": 0.92,
        "MXN": 18.20,
        "COP": 4_050,
        "ARS": 1_350,
        "CLP": 960,
        "PEN": 3.55,
        "BRL": 5.45,
        "UYU": 40.20,
        "DOP": 60.50,
        "CRC": 505,
        "GTQ": 7.70,
        "GBP": 0.78,
        "CAD": 1.36,
        "JPY": 155,
        "CNY": 7.18,
        "KRW": 1_380,
        "CHF": 0.82,
        "AUD": 1.53,
        "THB": 35.20
    ]

    static func defaults(for baseCurrency: String) -> [String: Decimal] {
        supportedCurrencies.reduce(into: [String: Decimal]()) { result, currency in
            result[currency] = defaultRate(from: currency, to: baseCurrency)
        }
    }

    static func defaultRate(from sourceCurrency: String, to baseCurrency: String) -> Decimal {
        guard sourceCurrency != baseCurrency else { return 1 }
        guard let sourcePerUSD = usdRates[sourceCurrency],
              let basePerUSD = usdRates[baseCurrency],
              sourcePerUSD > 0 else {
            return 1
        }

        return basePerUSD / sourcePerUSD
    }
}

// MARK: - Local persistence

final class TripStore: ObservableObject {
    @Published private(set) var trips: [Trip] = [] {
        didSet {
            saveTrips()
        }
    }

    private let storageKey = "Spendly.savedTrips.v3"
    private let spendlyLegacyStorageKey = "TravelSpend.savedTrips.v2"
    private let legacyStorageKey = "TravelSpend.savedTrips.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadTrips()
    }

    func trip(withID id: UUID) -> Trip? {
        trips.first { $0.id == id }
    }

    func addTrip(
        destination: String,
        budget: Decimal,
        currencyCode: String,
        startDate: Date,
        endDate: Date
    ) {
        let trip = Trip(
            destination: destination,
            budget: budget,
            currencyCode: currencyCode,
            startDate: startDate,
            endDate: endDate
        )

        trips.insert(trip, at: 0)
    }

    func addExampleTrip() {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let endDate = calendar.date(byAdding: .day, value: 5, to: today) ?? today
        let rates = ExchangeRateTable.defaults(for: "USD")

        func expense(
            _ title: String,
            _ amount: Decimal,
            _ currency: String,
            _ category: ExpenseCategory,
            dayOffset: Int,
            method: PaymentMethod,
            note: String = ""
        ) -> Expense {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let converted = amount * (rates[currency] ?? 1)
            return Expense(
                title: title,
                amount: converted,
                category: category,
                date: date,
                note: note,
                originalAmount: amount,
                originalCurrencyCode: currency,
                convertedAmount: converted,
                paymentMethod: method
            )
        }

        func itinerary(
            _ title: String,
            location: String,
            dayOffset: Int,
            hour: Int,
            durationHours: Int,
            notes: String = ""
        ) -> ItineraryItem {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
            let end = calendar.date(byAdding: .hour, value: durationHours, to: start) ?? start
            return ItineraryItem(
                title: title,
                location: location,
                startDate: start,
                endDate: end,
                notes: notes
            )
        }

        let example = Trip(
            destination: L10n.text("trip.example.destination"),
            budget: 1_850,
            currencyCode: "USD",
            startDate: startDate,
            endDate: endDate,
            expenses: [
                expense(L10n.text("trip.example.expense.round_trip"), 520, "USD", .flights, dayOffset: -2, method: .creditCard),
                expense(L10n.text("trip.example.expense.city_hotel"), 410, "EUR", .lodging, dayOffset: -1, method: .creditCard, note: L10n.text("trip.example.expense.hotel_reservation")),
                expense(L10n.text("trip.example.expense.airport_train"), 14, "EUR", .transportation, dayOffset: 0, method: .debitCard),
                expense(L10n.text("trip.example.expense.dinner_alfama"), 42, "EUR", .food, dayOffset: 0, method: .cash),
                expense(L10n.text("trip.example.expense.museum_view"), 28, "EUR", .entertainment, dayOffset: 1, method: .digitalWallet),
                expense(L10n.text("trip.example.expense.gifts"), 65, "EUR", .shopping, dayOffset: 1, method: .debitCard),
                expense(L10n.text("trip.example.expense.medicines"), 18, "EUR", .emergency, dayOffset: 2, method: .cash)
            ],
            categoryBudgets: [
                ExpenseCategory.flights.rawValue: 600,
                ExpenseCategory.lodging.rawValue: 500,
                ExpenseCategory.food.rawValue: 260,
                ExpenseCategory.transportation.rawValue: 120,
                ExpenseCategory.entertainment.rawValue: 180,
                ExpenseCategory.shopping.rawValue: 120,
                ExpenseCategory.emergency.rawValue: 70
            ],
            exchangeRates: rates,
            itineraryItems: [
                itinerary(L10n.text("trip.example.itinerary.checkin"), location: "Baixa, Lisboa", dayOffset: -1, hour: 15, durationHours: 1),
                itinerary(L10n.text("trip.example.itinerary.dinner"), location: "Alfama", dayOffset: 0, hour: 20, durationHours: 2, notes: L10n.text("trip.example.itinerary.reserve_note")),
                itinerary(L10n.text("trip.example.itinerary.museum"), location: "Belém", dayOffset: 1, hour: 10, durationHours: 4),
                itinerary(L10n.text("trip.example.itinerary.free_time"), location: "Chiado", dayOffset: 1, hour: 16, durationHours: 2)
            ]
        )

        trips.insert(example, at: 0)
    }

    func updateTrip(
        id: UUID,
        destination: String,
        budget: Decimal,
        currencyCode: String,
        startDate: Date,
        endDate: Date
    ) {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return }

        trips[index].destination = destination
        trips[index].budget = budget
        if trips[index].currencyCode != currencyCode {
            trips[index].currencyCode = currencyCode
            trips[index].exchangeRates = ExchangeRateTable.defaults(for: currencyCode)
        }
        trips[index].startDate = startDate
        trips[index].endDate = endDate
    }

    func deleteTrip(id: UUID) {
        trips.removeAll { $0.id == id }
    }

    func deleteTrips(ids: [UUID]) {
        trips.removeAll { ids.contains($0.id) }
    }

    func toggleClosed(tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[index].isClosed.toggle()
    }

    func addExpense(_ expense: Expense, to tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[index].expenses.append(expense)
    }

    func updateExpense(_ expense: Expense, in tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }
        guard let expenseIndex = trips[tripIndex].expenses.firstIndex(where: {
            $0.id == expense.id
        }) else { return }

        trips[tripIndex].expenses[expenseIndex] = expense
    }

    func updateCategoryBudgets(_ categoryBudgets: [String: Decimal], for tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[index].categoryBudgets = categoryBudgets
    }

    func updateExchangeRates(_ exchangeRates: [String: Decimal], for tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[index].exchangeRates = exchangeRates
        trips[index].expenses = trips[index].expenses.map { expense in
            var updated = expense
            let rate = exchangeRates[expense.originalCurrencyCode] ?? 1
            updated.convertedAmount = expense.originalAmount * rate
            updated.amount = updated.convertedAmount
            return updated
        }
    }

    func addItineraryItem(_ item: ItineraryItem, to tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[index].itineraryItems.append(item)
    }

    func updateItineraryItem(_ item: ItineraryItem, in tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }
        guard let itemIndex = trips[tripIndex].itineraryItems.firstIndex(where: { $0.id == item.id }) else { return }
        trips[tripIndex].itineraryItems[itemIndex] = item
    }

    func toggleItineraryItem(id: UUID, in tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }
        guard let itemIndex = trips[tripIndex].itineraryItems.firstIndex(where: { $0.id == id }) else { return }
        trips[tripIndex].itineraryItems[itemIndex].isCompleted.toggle()
    }

    func deleteItineraryItem(id: UUID, from tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[index].itineraryItems.removeAll { $0.id == id }
    }

    func deleteExpense(id: UUID, from tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[index].expenses.removeAll { $0.id == id }
    }

    private func saveTrips() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(trips)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("No se pudieron guardar los viajes: \(error.localizedDescription)")
        }
    }

    private func loadTrips() {
        let data = defaults.data(forKey: storageKey)
            ?? defaults.data(forKey: spendlyLegacyStorageKey)
            ?? defaults.data(forKey: legacyStorageKey)
        guard let data else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            trips = try decoder.decode([Trip].self, from: data)
        } catch {
            print("No se pudieron cargar los viajes: \(error.localizedDescription)")
        }
    }
}

// MARK: - Home

struct ContentView: View {
    @EnvironmentObject private var store: TripStore
    @State private var showingNewTrip = false

    private var activeTrips: [Trip] {
        store.trips
            .filter { !$0.isClosed }
            .sorted { $0.startDate < $1.startDate }
    }

    private var closedTrips: [Trip] {
        store.trips
            .filter(\.isClosed)
            .sorted { $0.endDate > $1.endDate }
    }

    var body: some View {
        Group {
            if store.trips.isEmpty {
                EmptyTripsView {
                    showingNewTrip = true
                } exploreExample: {
                    store.addExampleTrip()
                }
            } else {
                tripsList
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SpendlyLogoView()
            }

            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    CurrencyConverterView()
                } label: {
                    Image(systemName: "arrow.left.arrow.right.circle")
                }
                .accessibilityLabel(L10n.text("a11y.convert_currency"))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewTrip = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.text("a11y.new_trip"))
            }
        }
        .sheet(isPresented: $showingNewTrip) {
            NavigationStack {
                TripEditorView()
            }
            .environmentObject(store)
        }
    }

    private var tripsList: some View {
        List {
            if !activeTrips.isEmpty {
                Section(L10n.text("home.section_active_trips")) {
                    ForEach(activeTrips) { trip in
                        NavigationLink {
                            TripDetailView(tripID: trip.id)
                        } label: {
                            TripRowView(trip: trip)
                        }
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { activeTrips[$0].id }
                        store.deleteTrips(ids: ids)
                    }
                    .listRowBackground(Color.clear)
                }
            }

            if !closedTrips.isEmpty {
                Section(L10n.text("home.section_closed_trips")) {
                    ForEach(closedTrips) { trip in
                        NavigationLink {
                            TripDetailView(tripID: trip.id)
                        } label: {
                            TripRowView(trip: trip)
                        }
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { closedTrips[$0].id }
                        store.deleteTrips(ids: ids)
                    }
                    .listRowBackground(Color.clear)
                }
            }

            Section(L10n.text("home.section_tools")) {
                NavigationLink {
                    CurrencyConverterView()
                } label: {
                    Label(L10n.text("tool.convert_currency"), systemImage: "arrow.left.arrow.right.circle")
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .travelListSurface()
    }
}

private struct EmptyTripsView: View {
    let createTrip: () -> Void
    let exploreExample: () -> Void

    var body: some View {
        ZStack {
            TravelSpendBackground()

            VStack(spacing: 18) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text(L10n.text("home.empty_title"))
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(L10n.text("home.empty_subtitle"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Button(action: createTrip) {
                Label(L10n.text("home.empty_create_trip"), systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: exploreExample) {
                Label(L10n.text("home.empty_load_example"), systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            NavigationLink {
                CurrencyConverterView()
            } label: {
                Label(L10n.text("tool.convert_currency"), systemImage: "arrow.left.arrow.right.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            }
            .padding(24)
            .travelGlassPanel(tint: .blue.opacity(0.18), interactive: true)
            .padding(24)
            .frame(maxWidth: 520)
        }
    }
}

private struct TripRowView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(trip.destination)
                    .font(.headline)

                Spacer()

                Text(trip.budgetStatus.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(trip.budgetStatus.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Text(MoneyFormatter.string(trip.remaining, currencyCode: trip.currencyCode))
                .font(.title3.weight(.semibold))
                .foregroundStyle(trip.remaining < 0 ? .red : .primary)

            ProgressView(value: trip.budgetProgress)
                .tint(trip.budgetStatus.color)

            HStack {
                Label(L10n.text("trip.days_remaining", trip.daysRemaining()), systemImage: "calendar")
                Spacer()
                Text(L10n.text("trip.percent_used", Int(trip.budgetUsedPercent.rounded())))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
    }
}

// MARK: - Trip editor

struct TripEditorView: View {
    private enum Field: Hashable {
        case destination
        case budget
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    @FocusState private var focusedField: Field?

    private let existingTrip: Trip?

    @State private var destination: String
    @State private var budgetText: String
    @State private var currencyCode: String
    @State private var startDate: Date
    @State private var endDate: Date

    init(trip: Trip? = nil) {
        existingTrip = trip
        _destination = State(initialValue: trip?.destination ?? "")
        _budgetText = State(
            initialValue: trip.map { MoneyFormatter.editableString($0.budget) } ?? ""
        )
        _currencyCode = State(initialValue: trip?.currencyCode ?? "USD")
        _startDate = State(initialValue: trip?.startDate ?? Date())
        _endDate = State(
            initialValue: trip?.endDate
                ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())
                ?? Date()
        )
    }

    private var budget: Decimal? {
        MoneyFormatter.decimal(from: budgetText)
    }

    private var datesAreValid: Bool {
        Calendar.current.startOfDay(for: endDate)
            >= Calendar.current.startOfDay(for: startDate)
    }

    private var canSave: Bool {
        !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (budget ?? 0) > 0
            && datesAreValid
    }

    var body: some View {
        Form {
            Section(L10n.text("trip_editor.section_data")) {
                TextField(L10n.text("trip_editor.destination"), text: $destination)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .destination)

                TextField(L10n.text("trip_editor.budget"), text: $budgetText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .budget)

                Picker(L10n.text("trip_editor.base_currency"), selection: $currencyCode) {
                    ForEach(ExchangeRateTable.supportedCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .disabled(existingTrip?.expenses.isEmpty == false)

                if existingTrip?.expenses.isEmpty == false {
                    Text(L10n.text("trip_editor.base_currency_locked"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.text("trip_editor.section_dates")) {
                DatePicker(L10n.text("trip_editor.start_date"), selection: $startDate, displayedComponents: .date)
                DatePicker(L10n.text("trip_editor.end_date"), selection: $endDate, in: startDate..., displayedComponents: .date)
            }

            Section {
                Button(existingTrip == nil ? L10n.text("trip_editor.save_trip") : L10n.text("trip_editor.save_changes")) {
                    saveTrip()
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
        }
        .travelListSurface()
        .navigationTitle(existingTrip == nil ? L10n.text("trip_editor.add_title") : L10n.text("trip_editor.edit_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.text("action.cancel")) {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.text("action.done")) {
                    focusedField = nil
                }
            }
        }
    }

    private func saveTrip() {
        guard let budget else { return }

        let cleanDestination = destination
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingTrip {
            store.updateTrip(
                id: existingTrip.id,
                destination: cleanDestination,
                budget: budget,
                currencyCode: currencyCode,
                startDate: startDate,
                endDate: endDate
            )
        } else {
            store.addTrip(
                destination: cleanDestination,
                budget: budget,
                currencyCode: currencyCode,
                startDate: startDate,
                endDate: endDate
            )
        }

        dismiss()
    }
}

// MARK: - Trip detail

private struct ExpenseEditorRoute: Identifiable {
    let id: UUID
    let expense: Expense?

    init(expense: Expense? = nil) {
        id = expense?.id ?? UUID()
        self.expense = expense
    }
}

enum ExpenseSortOption: String, CaseIterable, Identifiable {
    case newest
    case highestAmount
    case category

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: L10n.text("expense_sort.newest")
        case .highestAmount: L10n.text("expense_sort.highest_amount")
        case .category: L10n.text("expense_sort.category")
        }
    }
}

struct TripDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore

    let tripID: UUID

    @State private var expenseRoute: ExpenseEditorRoute?
    @State private var showingEditTrip = false
    @State private var confirmingTripDeletion = false
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var sortOption: ExpenseSortOption = .newest
    @State private var filterByDate = false
    @State private var startFilterDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endFilterDate = Date()

    private var trip: Trip? {
        store.trip(withID: tripID)
    }

    var body: some View {
        Group {
            if let trip {
                tripList(trip)
            } else {
                Text(L10n.text("trip.not_found"))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(trip?.destination ?? L10n.text("trip.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let trip {
                if !trip.isClosed {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            expenseRoute = ExpenseEditorRoute()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(L10n.text("a11y.add_expense"))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink {
                            TripSummaryView(trip: trip)
                        } label: {
                            Label(L10n.text("trip.menu.advanced_summary"), systemImage: "doc.text.magnifyingglass")
                        }

                        ShareLink(
                            item: trip.shareReport,
                            subject: Text(L10n.text("trip.share.subject", trip.destination)),
                            message: Text(L10n.text("trip.share.message"))
                        ) {
                            Label(L10n.text("trip.menu.share_summary"), systemImage: "square.and.arrow.up")
                        }

                        ShareLink(item: trip.csvExport) {
                            Label(L10n.text("trip.menu.export_csv"), systemImage: "tablecells")
                        }

                        Button {
                            showingEditTrip = true
                        } label: {
                            Label(L10n.text("trip.menu.edit_trip"), systemImage: "pencil")
                        }

                        Button {
                            store.toggleClosed(tripID: tripID)
                        } label: {
                            Label(
                                trip.isClosed ? L10n.text("trip.menu.reopen_trip") : L10n.text("trip.menu.close_trip"),
                                systemImage: trip.isClosed
                                    ? "arrow.uturn.backward"
                                    : "checkmark.circle"
                            )
                        }

                        Divider()

                        Button(role: .destructive) {
                            confirmingTripDeletion = true
                        } label: {
                            Label(L10n.text("trip.menu.delete_trip"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel(L10n.text("a11y.more_options"))
                }
            }
        }
        .sheet(item: $expenseRoute) { route in
            NavigationStack {
                ExpenseEditorView(
                    tripID: tripID,
                    expense: route.expense
                )
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingEditTrip) {
            if let trip {
                NavigationStack {
                    TripEditorView(trip: trip)
                }
                .environmentObject(store)
            }
        }
        .alert(L10n.text("trip.delete.title"), isPresented: $confirmingTripDeletion) {
            Button(L10n.text("action.cancel"), role: .cancel) { }
            Button(L10n.text("action.delete"), role: .destructive) {
                store.deleteTrip(id: tripID)
                dismiss()
            }
        } message: {
            Text(L10n.text("trip.delete.message"))
        }
    }

    private func tripList(_ trip: Trip) -> some View {
        let expenses = filteredExpenses(for: trip)

        return List {
            Section {
                BudgetDashboardView(trip: trip)
            }

            Section {
                CategoryDonutChartView(
                    trip: trip,
                    selectedCategory: $selectedCategory
                )
            } header: {
                Text(L10n.text("trip.section_spending_by_category"))
            } footer: {
                if selectedCategory != nil {
                    Button(L10n.text("trip.clear_category_filter")) {
                        selectedCategory = nil
                    }
                }
            }

            Section(L10n.text("trip.section_tools")) {
                NavigationLink {
                    ExchangeRateEditorView(trip: trip)
                } label: {
                    Label(L10n.text("trip.tools.exchange_rates"), systemImage: "coloncurrencysign.arrow.circlepath")
                }

                NavigationLink {
                    CategoryBudgetEditorView(trip: trip)
                } label: {
                    Label(L10n.text("trip.tools.plan_by_category"), systemImage: "slider.horizontal.3")
                }

                NavigationLink {
                    ItineraryPlannerView(trip: trip)
                } label: {
                    Label(L10n.text("trip.tools.itinerary"), systemImage: "map")
                }

                NavigationLink {
                    TripSummaryView(trip: trip)
                } label: {
                    Label(L10n.text("trip.tools.summary_export"), systemImage: "doc.text")
                }
            }

            Section(L10n.text("trip.section_upcoming_itinerary")) {
                if trip.itineraryItems.isEmpty {
                    ContentUnavailableView(
                        L10n.text("trip.itinerary.empty"),
                        systemImage: "map",
                        description: Text(L10n.text("trip.itinerary.empty_desc"))
                    )
                } else {
                    ForEach(trip.itineraryItems.sorted { $0.startDate < $1.startDate }.prefix(3)) { item in
                        ItineraryCompactRow(item: item)
                    }

                    NavigationLink {
                        ItineraryPlannerView(trip: trip)
                    } label: {
                        Label(L10n.text("trip.itinerary.view_all"), systemImage: "list.bullet.rectangle")
                    }
                }
            }

            Section(L10n.text("trip.section_search_filter")) {
                TextField(L10n.text("trip.search_placeholder"), text: $searchText)
                    .textInputAutocapitalization(.sentences)

                Picker(L10n.text("trip.filter_category"), selection: $selectedCategory) {
                    Text(L10n.text("trip.filter_category_all")).tag(Optional<ExpenseCategory>.none)
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.name, systemImage: category.icon)
                            .tag(Optional(category))
                    }
                }

                Picker(L10n.text("trip.filter_sort"), selection: $sortOption) {
                    ForEach(ExpenseSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Toggle(L10n.text("trip.filter_by_date"), isOn: $filterByDate)
                if filterByDate {
                    DatePicker(L10n.text("trip.filter_date_from"), selection: $startFilterDate, displayedComponents: .date)
                    DatePicker(L10n.text("trip.filter_date_to"), selection: $endFilterDate, displayedComponents: .date)
                }
            }

            Section(L10n.text("trip.section_filtered_expenses")) {
                if trip.expenses.isEmpty {
                    EmptyExpensesView(isClosed: trip.isClosed)
                } else if expenses.isEmpty {
                    ContentUnavailableView(
                        L10n.text("trip.no_results"),
                        systemImage: "magnifyingglass",
                        description: Text(L10n.text("trip.no_results_desc"))
                    )
                } else {
                    ForEach(expenses) { expense in
                        ExpenseRowView(
                            expense: expense,
                            baseCurrencyCode: trip.currencyCode
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !trip.isClosed else { return }
                            expenseRoute = ExpenseEditorRoute(expense: expense)
                        }
                        .swipeActions(edge: .trailing) {
                            if !trip.isClosed {
                                Button(role: .destructive) {
                                    store.deleteExpense(
                                        id: expense.id,
                                        from: tripID
                                    )
                                } label: {
                                    Label(L10n.text("action.delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }

            Section(L10n.text("trip.section_info")) {
                LabeledContent(
                    L10n.text("trip.info_start"),
                    value: trip.startDate.formatted(date: .abbreviated, time: .omitted)
                )
                LabeledContent(
                    L10n.text("trip.info_end"),
                    value: trip.endDate.formatted(date: .abbreviated, time: .omitted)
                )
                LabeledContent(L10n.text("trip.info_currency"), value: trip.currencyCode)
                LabeledContent(L10n.text("trip.info_expenses_count"), value: "\(trip.expenses.count)")
            }
        }
        .listStyle(.insetGrouped)
        .travelListSurface()
    }

    private func filteredExpenses(for trip: Trip) -> [Expense] {
        let calendar = Calendar.autoupdatingCurrent
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let startDay = calendar.startOfDay(for: startFilterDate)
        let endDay = calendar.startOfDay(for: endFilterDate)

        let filtered = trip.expenses.filter { expense in
            let matchesSearch = query.isEmpty
                || expense.title.lowercased().contains(query)
                || expense.note.lowercased().contains(query)
            let matchesCategory = selectedCategory == nil || expense.category == selectedCategory
            let matchesDate: Bool

            if filterByDate {
                let expenseDay = calendar.startOfDay(for: expense.date)
                matchesDate = expenseDay >= min(startDay, endDay) && expenseDay <= max(startDay, endDay)
            } else {
                matchesDate = true
            }

            return matchesSearch && matchesCategory && matchesDate
        }

        switch sortOption {
        case .newest:
            return filtered.sorted { $0.date > $1.date }
        case .highestAmount:
            return filtered.sorted { $0.convertedAmount > $1.convertedAmount }
        case .category:
            return filtered.sorted {
                if $0.category.name == $1.category.name {
                    return $0.date > $1.date
                }
                return $0.category.name < $1.category.name
            }
        }
    }
}

private struct EmptyExpensesView: View {
    let isClosed: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "creditcard")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(L10n.text("expenses.empty_title"))
                .fontWeight(.medium)

            if !isClosed {
                Text(L10n.text("expenses.empty_hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct ItineraryEditorRoute: Identifiable {
    let id: UUID
    let item: ItineraryItem?

    init(item: ItineraryItem? = nil) {
        id = item?.id ?? UUID()
        self.item = item
    }
}

struct ItineraryPlannerView: View {
    @EnvironmentObject private var store: TripStore

    let tripID: UUID
    let tripStartDate: Date
    let tripEndDate: Date

    @State private var editorRoute: ItineraryEditorRoute?

    init(trip: Trip) {
        tripID = trip.id
        tripStartDate = trip.startDate
        tripEndDate = trip.endDate
    }

    private var trip: Trip? {
        store.trip(withID: tripID)
    }

    private var sortedItems: [ItineraryItem] {
        trip?.itineraryItems.sorted { $0.startDate < $1.startDate } ?? []
    }

    var body: some View {
        List {
            Section {
                if sortedItems.isEmpty {
                    ContentUnavailableView(
                        L10n.text("itinerary.empty"),
                        systemImage: "map",
                        description: Text(L10n.text("itinerary.empty_desc"))
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(sortedItems) { item in
                        ItineraryRow(item: item) {
                            store.toggleItineraryItem(id: item.id, in: tripID)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editorRoute = ItineraryEditorRoute(item: item)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.deleteItineraryItem(id: item.id, from: tripID)
                            } label: {
                                Label(L10n.text("action.delete"), systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text(L10n.text("itinerary.section_title"))
            } footer: {
                Text(L10n.text("itinerary.footer"))
            }
        }
        .listStyle(.insetGrouped)
        .travelListSurface()
        .navigationTitle(L10n.text("itinerary.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorRoute = ItineraryEditorRoute()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.text("a11y.add_activity"))
            }
        }
        .sheet(item: $editorRoute) { route in
            NavigationStack {
                ItineraryEditorView(
                    tripID: tripID,
                    tripStartDate: tripStartDate,
                    tripEndDate: tripEndDate,
                    item: route.item
                )
            }
            .environmentObject(store)
        }
    }
}

private struct ItineraryCompactRow: View {
    let item: ItineraryItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "clock")
                .foregroundStyle(item.isCompleted ? .green : .blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .fontWeight(.medium)
                Text(item.startDate, format: .dateTime.day().month(.abbreviated).hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct ItineraryRow: View {
    let item: ItineraryItem
    let toggleCompletion: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: toggleCompletion) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .strikethrough(item.isCompleted)

                HStack {
                    Image(systemName: "calendar")
                    Text(item.startDate, format: .dateTime.day().month(.abbreviated).hour().minute())
                    Text("-")
                    Text(item.endDate, format: .dateTime.hour().minute())
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !item.location.isEmpty {
                    Label(item.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ItineraryEditorView: View {
    private enum Field: Hashable {
        case title
        case location
        case notes
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    @FocusState private var focusedField: Field?

    let tripID: UUID
    let tripStartDate: Date
    let tripEndDate: Date
    private let existingItem: ItineraryItem?

    @State private var title: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var isCompleted: Bool

    init(
        tripID: UUID,
        tripStartDate: Date,
        tripEndDate: Date,
        item: ItineraryItem? = nil
    ) {
        self.tripID = tripID
        self.tripStartDate = tripStartDate
        self.tripEndDate = tripEndDate
        existingItem = item

        let defaultStart = item?.startDate ?? tripStartDate
        _title = State(initialValue: item?.title ?? "")
        _location = State(initialValue: item?.location ?? "")
        _startDate = State(initialValue: defaultStart)
        _endDate = State(initialValue: item?.endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: defaultStart) ?? defaultStart)
        _notes = State(initialValue: item?.notes ?? "")
        _isCompleted = State(initialValue: item?.isCompleted ?? false)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && endDate >= startDate
    }

    private var tripDateRange: ClosedRange<Date> {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: tripStartDate)
        let endDay = calendar.startOfDay(for: tripEndDate)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endDay) ?? tripEndDate
        return start...end
    }

        var body: some View {
        Form {
            Section(L10n.text("itinerary_editor.section_title")) {
                TextField(L10n.text("itinerary_editor.title"), text: $title)
                    .focused($focusedField, equals: .title)
                    .textInputAutocapitalization(.sentences)

                TextField(L10n.text("itinerary_editor.location"), text: $location)
                    .focused($focusedField, equals: .location)
                    .textInputAutocapitalization(.words)

                DatePicker(L10n.text("itinerary_editor.start"), selection: $startDate, in: tripDateRange, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: startDate) { _, newValue in
                        if endDate < newValue {
                            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                        }
                    }

                DatePicker(L10n.text("itinerary_editor.end"), selection: $endDate, in: startDate...tripDateRange.upperBound, displayedComponents: [.date, .hourAndMinute])

                Toggle(L10n.text("itinerary_editor.completed"), isOn: $isCompleted)
            }

            Section(L10n.text("itinerary_editor.notes")) {
                TextField(L10n.text("itinerary_editor.notes_placeholder"), text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: .notes)
            }

            Section {
                Button(existingItem == nil ? L10n.text("itinerary_editor.save_activity") : L10n.text("itinerary_editor.save_changes")) {
                    saveItem()
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
        }
        .travelListSurface()
        .navigationTitle(existingItem == nil ? L10n.text("itinerary_editor.add_title") : L10n.text("itinerary_editor.edit_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.text("action.cancel")) {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.text("action.done")) {
                    focusedField = nil
                }
            }
        }
    }

    private func saveItem() {
        let item = ItineraryItem(
            id: existingItem?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: endDate,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: isCompleted
        )

        if existingItem == nil {
            store.addItineraryItem(item, to: tripID)
        } else {
            store.updateItineraryItem(item, in: tripID)
        }

        dismiss()
    }
}

private struct ExpenseRowView: View {
    let expense: Expense
    let baseCurrencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.icon)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(expense.category.color, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .fontWeight(.medium)

                Text("\(expense.category.name) · \(expense.paymentMethod.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(MoneyFormatter.string(expense.convertedAmount, currencyCode: baseCurrencyCode))
                    .fontWeight(.semibold)

                Text(L10n.text("expense_row.original_suffix", MoneyFormatter.string(expense.originalAmount, currencyCode: expense.originalCurrencyCode)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Expense editor

struct ExpenseEditorView: View {
    private enum Field: Hashable {
        case title
        case amount
        case note
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore
    @FocusState private var focusedField: Field?

    let tripID: UUID
    private let existingExpense: Expense?

    @State private var title: String
    @State private var originalAmountText: String
    @State private var originalCurrencyCode: String
    @State private var category: ExpenseCategory
    @State private var paymentMethod: PaymentMethod
    @State private var date: Date
    @State private var note: String
    @State private var confirmingDeletion = false

    init(tripID: UUID, expense: Expense? = nil) {
        self.tripID = tripID
        existingExpense = expense
        _title = State(initialValue: expense?.title ?? "")
        _originalAmountText = State(
            initialValue: expense.map { MoneyFormatter.editableString($0.originalAmount) } ?? ""
        )
        _originalCurrencyCode = State(initialValue: expense?.originalCurrencyCode ?? "USD")
        _category = State(initialValue: expense?.category ?? .food)
        _paymentMethod = State(initialValue: expense?.paymentMethod ?? .creditCard)
        _date = State(initialValue: expense?.date ?? Date())
        _note = State(initialValue: expense?.note ?? "")
    }

    private var trip: Trip? {
        store.trip(withID: tripID)
    }

    private var originalAmount: Decimal? {
        MoneyFormatter.decimal(from: originalAmountText)
    }

    private var convertedAmount: Decimal? {
        guard let trip, let originalAmount else { return nil }
        return trip.convertedAmount(for: originalAmount, currencyCode: originalCurrencyCode)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (originalAmount ?? 0) > 0
            && trip != nil
    }

        var body: some View {
        Form {
            Section(L10n.text("expense_editor.section_title")) {
                TextField(L10n.text("expense_editor.title_hint"), text: $title)
                    .textInputAutocapitalization(.sentences)
                    .focused($focusedField, equals: .title)

                TextField(L10n.text("expense_editor.original_amount"), text: $originalAmountText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)

                Picker(L10n.text("expense_editor.original_currency"), selection: $originalCurrencyCode) {
                    ForEach(ExchangeRateTable.supportedCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }

                if let trip, let convertedAmount {
                    LabeledContent(L10n.text("expense_editor.converted_to", trip.currencyCode)) {
                        Text(MoneyFormatter.string(convertedAmount, currencyCode: trip.currencyCode))
                            .fontWeight(.semibold)
                    }
                }

                Picker(L10n.text("expense_editor.category"), selection: $category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.name, systemImage: category.icon)
                            .tag(category)
                    }
                }

                Picker(L10n.text("expense_editor.payment_method"), selection: $paymentMethod) {
                    ForEach(PaymentMethod.allCases) { method in
                        Label(method.name, systemImage: method.icon)
                            .tag(method)
                    }
                }

                DatePicker(L10n.text("expense_editor.date"), selection: $date, displayedComponents: .date)
            }

            Section(L10n.text("expense_editor.notes")) {
                TextField(L10n.text("expense_editor.notes_placeholder"), text: $note, axis: .vertical)
                    .lineLimit(2...4)
                    .focused($focusedField, equals: .note)
            }

            Section {
                Button(existingExpense == nil ? L10n.text("expense_editor.save_expense") : L10n.text("expense_editor.save_changes")) {
                    saveExpense()
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .disabled(!canSave)
            }

            if existingExpense != nil {
                Section {
                    Button(L10n.text("expense_editor.delete_expense"), role: .destructive) {
                        confirmingDeletion = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .travelListSurface()
        .navigationTitle(existingExpense == nil ? L10n.text("expense_editor.add_title") : L10n.text("expense_editor.edit_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.text("action.cancel")) {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.text("action.done")) {
                    focusedField = nil
                }
            }
        }
        .alert(L10n.text("expense_editor.delete.title"), isPresented: $confirmingDeletion) {
            Button(L10n.text("action.cancel"), role: .cancel) { }
            Button(L10n.text("action.delete"), role: .destructive) {
                if let existingExpense {
                    store.deleteExpense(id: existingExpense.id, from: tripID)
                }
                dismiss()
            }
        } message: {
            Text(L10n.text("expense_editor.delete.message"))
        }
    }

    private func saveExpense() {
        guard let originalAmount, let trip else { return }
        let convertedAmount = trip.convertedAmount(for: originalAmount, currencyCode: originalCurrencyCode)

        let expense = Expense(
            id: existingExpense?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: convertedAmount,
            category: category,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            originalAmount: originalAmount,
            originalCurrencyCode: originalCurrencyCode,
            convertedAmount: convertedAmount,
            paymentMethod: paymentMethod
        )

        if existingExpense == nil {
            store.addExpense(expense, to: tripID)
        } else {
            store.updateExpense(expense, in: tripID)
        }

        dismiss()
    }
}
