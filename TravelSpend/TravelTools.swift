import Charts
import Foundation
import SwiftUI

// MARK: - Trip planning and insights

enum BudgetStatus: Equatable {
    case onTrack
    case spendingFast
    case overBudget

    var title: String {
        switch self {
        case .onTrack: L10n.text("budget_status.on_track_title")
        case .spendingFast: L10n.text("budget_status.spending_fast_title")
        case .overBudget: L10n.text("budget_status.over_budget_title")
        }
    }

    var detail: String {
        switch self {
        case .onTrack: L10n.text("budget_status.on_track_detail")
        case .spendingFast: L10n.text("budget_status.spending_fast_detail")
        case .overBudget: L10n.text("budget_status.over_budget_detail")
        }
    }

    var color: Color {
        switch self {
        case .onTrack: .green
        case .spendingFast: .orange
        case .overBudget: .red
        }
    }
}

extension Trip {
    var totalTripDays: Int {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }

    func daysElapsed(asOf date: Date = Date()) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let current = calendar.startOfDay(for: date)

        if current < start { return 0 }
        if current > end { return totalTripDays }

        return (calendar.dateComponents([.day], from: start, to: current).day ?? 0) + 1
    }

    func daysRemaining(asOf date: Date = Date()) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let current = calendar.startOfDay(for: date)

        if current > end { return 0 }
        if current <= start { return totalTripDays }

        return (calendar.dateComponents([.day], from: current, to: end).day ?? 0) + 1
    }

    func dailyAllowance(asOf date: Date = Date()) -> Decimal? {
        let days = daysRemaining(asOf: date)
        guard days > 0, !isClosed else { return nil }
        return remaining / Decimal(days)
    }

    var dailyAllowance: Decimal? {
        dailyAllowance()
    }

    func averageDailySpend(asOf date: Date = Date()) -> Decimal? {
        let days = daysElapsed(asOf: date)
        guard days > 0 else { return nil }
        return totalSpent / Decimal(days)
    }

    var averageDailySpend: Decimal? {
        averageDailySpend()
    }

    func projectedTotal(asOf date: Date = Date()) -> Decimal? {
        guard let averageDailySpend = averageDailySpend(asOf: date), daysElapsed(asOf: date) > 0 else {
            return nil
        }
        return averageDailySpend * Decimal(totalTripDays)
    }

    var projectedTotal: Decimal? {
        projectedTotal()
    }

    var isProjectedOverBudget: Bool {
        guard let projectedTotal else { return false }
        return projectedTotal > budget
    }

    var plannedTotal: Decimal {
        categoryBudgets.values.reduce(Decimal.zero, +)
    }

    var unassignedBudget: Decimal {
        budget - plannedTotal
    }

    var budgetStatus: BudgetStatus {
        if isOverBudget {
            return .overBudget
        }

        if isProjectedOverBudget {
            return .spendingFast
        }

        return .onTrack
    }

    func plannedBudget(for category: ExpenseCategory) -> Decimal? {
        categoryBudgets[category.rawValue]
    }

    func remainingBudget(for category: ExpenseCategory) -> Decimal? {
        guard let planned = plannedBudget(for: category) else { return nil }
        return planned - total(for: category)
    }

    var categoryBreakdown: [CategorySpend] {
        ExpenseCategory.allCases.compactMap { category in
            let amount = total(for: category)
            guard amount > 0 else { return nil }
            let percent = totalSpent > 0
                ? NSDecimalNumber(decimal: amount / totalSpent).doubleValue * 100
                : 0
            return CategorySpend(category: category, amount: amount, percent: percent)
        }
        .sorted { $0.amount > $1.amount }
    }

    var biggestCategory: CategorySpend? {
        categoryBreakdown.first
    }

    var mostExpensiveDay: DailySpend? {
        let calendar = Calendar.autoupdatingCurrent
        let totals = expenses.reduce(into: [Date: Decimal]()) { result, expense in
            let day = calendar.startOfDay(for: expense.date)
            result[day, default: 0] += expense.convertedAmount
        }

        return totals
            .map { DailySpend(date: $0.key, amount: $0.value) }
            .max { $0.amount < $1.amount }
    }

    var shareReport: String {
        var lines = [
            L10n.text("trip_share.header", L10n.text("app.name"), destination),
            "\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))",
            "",
            L10n.text("trip_share.status", budgetStatus.title),
            L10n.text("trip_share.budget", MoneyFormatter.string(budget, currencyCode: currencyCode)),
            L10n.text("trip_share.spent", MoneyFormatter.string(totalSpent, currencyCode: currencyCode)),
            L10n.text("trip_share.remaining", MoneyFormatter.string(remaining, currencyCode: currencyCode)),
            L10n.text("trip_share.used_percent", budgetUsedPercent.formatted(.number.precision(.fractionLength(0)))),
            L10n.text("trip_share.days_remaining", daysRemaining())
        ]

        if let averageDailySpend {
            lines.append(
                L10n.text("trip_share.average_daily", MoneyFormatter.string(averageDailySpend, currencyCode: currencyCode))
            )
        }

        if let dailyAllowance {
            lines.append(
                L10n.text("trip_share.daily_recommendation", MoneyFormatter.string(dailyAllowance, currencyCode: currencyCode))
            )
        }

        if let biggestCategory {
            lines.append(
                L10n.text(
                    "trip_share.top_category",
                    biggestCategory.category.name,
                    MoneyFormatter.string(biggestCategory.amount, currencyCode: currencyCode)
                )
            )
        }

        let categoryLines = categoryBreakdown.map { spend in
            L10n.text(
                "trip_share.category_line",
                spend.category.name,
                MoneyFormatter.string(spend.amount, currencyCode: currencyCode),
                spend.percent.formatted(.number.precision(.fractionLength(0)))
            )
        }

        if !categoryLines.isEmpty {
            lines.append("")
            lines.append(L10n.text("trip_share.expenses_by_category"))
            lines.append(contentsOf: categoryLines)
        }

        let itineraryLines = itineraryItems
            .sorted { $0.startDate < $1.startDate }
            .map { item in
                "- \(item.startDate.formatted(date: .abbreviated, time: .shortened)): \(item.title)\(item.location.isEmpty ? "" : " · \(item.location)")"
            }

        if !itineraryLines.isEmpty {
            lines.append("")
            lines.append(L10n.text("trip_share.itinerary"))
            lines.append(contentsOf: itineraryLines)
        }

        return lines.joined(separator: "\n")
    }

    var csvExport: String {
        let header = L10n.text("trip_csv.header")
        let rows = expenses.sorted { $0.date < $1.date }.map { expense in
            [
                expense.date.formatted(date: .numeric, time: .omitted),
                expense.title,
                expense.category.name,
                expense.paymentMethod.name,
                MoneyFormatter.editableString(expense.originalAmount),
                expense.originalCurrencyCode,
                MoneyFormatter.editableString(expense.convertedAmount),
                currencyCode,
                expense.note
            ]
            .map(Self.csvField)
            .joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    nonisolated private static func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

struct CategorySpend: Identifiable {
    let category: ExpenseCategory
    let amount: Decimal
    let percent: Double

    var id: String { category.rawValue }
    var amountDouble: Double { NSDecimalNumber(decimal: amount).doubleValue }
}

struct DailySpend: Identifiable {
    let date: Date
    let amount: Decimal

    var id: Date { date }
}

// MARK: - Dashboard

struct BudgetDashboardView: View {
    let trip: Trip

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.destination)
                        .font(.headline)
                    Text(trip.budgetStatus.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(trip.budgetStatus.color)
                }

                Spacer()

                Text(trip.currencyCode)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(MoneyFormatter.string(trip.remaining, currencyCode: trip.currencyCode))
                    .font(.largeTitle.bold())
                    .foregroundStyle(trip.remaining < 0 ? .red : .primary)
                    .minimumScaleFactor(0.7)

                ProgressView(value: trip.budgetProgress)
                    .tint(trip.budgetStatus.color)

                Text(trip.budgetStatus.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                MetricTile(L10n.text("trip_metric.budget"), MoneyFormatter.string(trip.budget, currencyCode: trip.currencyCode), "banknote")
                MetricTile(L10n.text("trip_metric.spent"), MoneyFormatter.string(trip.totalSpent, currencyCode: trip.currencyCode), "creditcard")
                MetricTile(L10n.text("trip_metric.used"), "\(Int(trip.budgetUsedPercent.rounded()))%", "chart.pie")
                MetricTile(L10n.text("trip_metric.days_remaining"), "\(trip.daysRemaining())", "calendar")
                MetricTile(
                    L10n.text("trip_metric.average_daily"),
                    trip.averageDailySpend.map { MoneyFormatter.string($0, currencyCode: trip.currencyCode) } ?? "-",
                    "chart.line.uptrend.xyaxis"
                )
                MetricTile(
                    L10n.text("trip_metric.recommended_daily"),
                    trip.dailyAllowance.map { MoneyFormatter.string($0, currencyCode: trip.currencyCode) } ?? "-",
                    "calendar.badge.clock"
                )
            }

            HStack {
                Label(trip.startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "play.circle")
                Spacer()
                Label(trip.endDate.formatted(date: .abbreviated, time: .omitted), systemImage: "flag.checkered")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .travelGlassPanel(
            tint: trip.budgetStatus.color.opacity(0.14),
            interactive: true
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let icon: String

    init(_ title: String, _ value: String, _ icon: String) {
        self.title = title
        self.value = value
        self.icon = icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Category chart

struct CategoryDonutChartView: View {
    let trip: Trip
    @Binding var selectedCategory: ExpenseCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if trip.categoryBreakdown.isEmpty {
                ContentUnavailableView(
                    L10n.text("category_chart.empty"),
                    systemImage: "chart.pie",
                    description: Text(L10n.text("category_chart.empty_desc"))
                )
                .frame(maxWidth: .infinity)
            } else {
                Chart(trip.categoryBreakdown) { item in
                    SectorMark(
                        angle: .value(L10n.text("chart.amount"), item.amountDouble),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.6
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.category.color)
                    .opacity(selectedCategory == nil || selectedCategory == item.category ? 1 : 0.32)
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .overlay {
                    VStack(spacing: 4) {
                        Text(MoneyFormatter.string(trip.totalSpent, currencyCode: trip.currencyCode))
                            .font(.headline)
                            .minimumScaleFactor(0.7)
                        Text(L10n.text("category_chart.total_label"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 18)
                }

                VStack(spacing: 8) {
                    ForEach(trip.categoryBreakdown) { item in
                        Button {
                            selectedCategory = selectedCategory == item.category ? nil : item.category
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(item.category.color)
                                    .frame(width: 10, height: 10)

                                Label(item.category.name, systemImage: item.category.icon)
                                    .labelStyle(.titleAndIcon)

                                Spacer()

                                Text("\(item.percent.formatted(.number.precision(.fractionLength(0))))%")
                                    .foregroundStyle(.secondary)

                                Text(MoneyFormatter.string(item.amount, currencyCode: trip.currencyCode))
                                    .fontWeight(.semibold)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selectedCategory == nil || selectedCategory == item.category ? .primary : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Category budgets

private struct CategoryBudgetDraft: Identifiable {
    let category: ExpenseCategory
    var amountText: String

    var id: String { category.rawValue }
}

struct CategoryBudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore

    let tripID: UUID
    let totalBudget: Decimal
    let currencyCode: String

    @State private var drafts: [CategoryBudgetDraft]

    init(trip: Trip) {
        tripID = trip.id
        totalBudget = trip.budget
        currencyCode = trip.currencyCode
        _drafts = State(initialValue: ExpenseCategory.allCases.map { category in
            CategoryBudgetDraft(
                category: category,
                amountText: trip.plannedBudget(for: category).map(MoneyFormatter.editableString) ?? ""
            )
        })
    }

    private var plannedTotal: Decimal {
        drafts.reduce(Decimal.zero) { partialResult, draft in
            partialResult + (MoneyFormatter.decimal(from: draft.amountText) ?? 0)
        }
    }

    private var hasInvalidAmount: Bool {
        drafts.contains { draft in
            let text = draft.amountText.trimmingCharacters(in: .whitespacesAndNewlines)
            return !text.isEmpty && ((MoneyFormatter.decimal(from: text) ?? -1) < 0)
        }
    }

    private var canSave: Bool {
        !hasInvalidAmount && plannedTotal <= totalBudget
    }

    var body: some View {
        Form {
            Section {
                LabeledContent(L10n.text("budget_plan.total")) {
                    Text(MoneyFormatter.string(totalBudget, currencyCode: currencyCode))
                }
                LabeledContent(L10n.text("budget_plan.assigned")) {
                    Text(MoneyFormatter.string(plannedTotal, currencyCode: currencyCode))
                        .foregroundStyle(plannedTotal > totalBudget ? .red : .primary)
                }
                LabeledContent(L10n.text("budget_plan.remaining")) {
                    Text(MoneyFormatter.string(totalBudget - plannedTotal, currencyCode: currencyCode))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(L10n.text("budget_plan.title"))
            } footer: {
                Text(L10n.text("budget_plan.help"))
            }

            Section(L10n.text("budget_plan.categories")) {
                ForEach($drafts) { $draft in
                    HStack(spacing: 12) {
                        Label(draft.category.name, systemImage: draft.category.icon)
                            .foregroundStyle(draft.category.color)

                        Spacer()

                        TextField(L10n.text("budget_plan.no_limit"), text: $draft.amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 110)

                        Text(currencyCode)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if plannedTotal > totalBudget {
                Section {
                    Label(L10n.text("budget_plan.validation"), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .travelListSurface()
        .navigationTitle(L10n.text("budget_plan.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("action.save")) {
                    savePlan()
                }
                .disabled(!canSave)
            }
        }
    }

    private func savePlan() {
        let budgets = drafts.reduce(into: [String: Decimal]()) { result, draft in
            guard let amount = MoneyFormatter.decimal(from: draft.amountText), amount > 0 else {
                return
            }
            result[draft.category.rawValue] = amount
        }

        store.updateCategoryBudgets(budgets, for: tripID)
        dismiss()
    }
}

// MARK: - Exchange rates

private struct ExchangeRateDraft: Identifiable {
    let currencyCode: String
    var rateText: String

    var id: String { currencyCode }
}

struct ExchangeRateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TripStore

    let tripID: UUID
    let baseCurrencyCode: String

    @State private var drafts: [ExchangeRateDraft]

    init(trip: Trip) {
        tripID = trip.id
        baseCurrencyCode = trip.currencyCode
        _drafts = State(initialValue: ExchangeRateTable.supportedCurrencies.map { currency in
            let rate = currency == trip.currencyCode ? 1 : trip.rate(for: currency)
            return ExchangeRateDraft(currencyCode: currency, rateText: MoneyFormatter.editableString(rate))
        })
    }

    private var canSave: Bool {
        drafts.allSatisfy { draft in
            guard let rate = MoneyFormatter.decimal(from: draft.rateText) else { return false }
            return rate > 0
        }
    }

    var body: some View {
        Form {
            Section {
                ForEach($drafts) { $draft in
                    HStack {
                        Text("1 \(draft.currencyCode)")
                        Spacer()
                        TextField(L10n.text("exchange_rate.rate"), text: $draft.rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .disabled(draft.currencyCode == baseCurrencyCode)
                            .frame(maxWidth: 120)
                        Text(baseCurrencyCode)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(L10n.text("exchange_rate.section_title"))
            } footer: {
                Text(L10n.text("exchange_rate.footer"))
            }
        }
        .travelListSurface()
        .navigationTitle(L10n.text("exchange_rate.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("action.save")) {
                    saveRates()
                }
                .disabled(!canSave)
            }
        }
    }

    private func saveRates() {
        let rates = drafts.reduce(into: [String: Decimal]()) { result, draft in
            result[draft.currencyCode] = MoneyFormatter.decimal(from: draft.rateText) ?? 1
        }

        store.updateExchangeRates(rates, for: tripID)
        dismiss()
    }
}

// MARK: - Summary

struct TripSummaryView: View {
    let trip: Trip

    var body: some View {
        List {
            Section {
                BudgetDashboardView(trip: trip)
            }

            Section(L10n.text("summary.section_title")) {
                LabeledContent(L10n.text("summary.total_spent")) {
                    Text(MoneyFormatter.string(trip.totalSpent, currencyCode: trip.currencyCode))
                }
                LabeledContent(L10n.text("summary.available")) {
                    Text(MoneyFormatter.string(trip.remaining, currencyCode: trip.currencyCode))
                        .foregroundStyle(trip.remaining < 0 ? .red : .primary)
                }
                LabeledContent(L10n.text("summary.top_category")) {
                    Text(trip.biggestCategory?.category.name ?? "-")
                }
                LabeledContent(L10n.text("summary.most_expensive_day")) {
                    if let day = trip.mostExpensiveDay {
                        Text("\(day.date.formatted(date: .abbreviated, time: .omitted)) · \(MoneyFormatter.string(day.amount, currencyCode: trip.currencyCode))")
                    } else {
                        Text("-")
                    }
                }
                LabeledContent(L10n.text("summary.average_daily")) {
                    Text(trip.averageDailySpend.map { MoneyFormatter.string($0, currencyCode: trip.currencyCode) } ?? "-")
                }
                LabeledContent(L10n.text("summary.status")) {
                    Text(trip.budgetStatus.title)
                        .foregroundStyle(trip.budgetStatus.color)
                }
            }

            Section(L10n.text("summary.share_section")) {
                ShareLink(item: trip.shareReport) {
                    Label(L10n.text("summary.share_text"), systemImage: "square.and.arrow.up")
                }

                ShareLink(item: trip.csvExport) {
                    Label(L10n.text("summary.share_csv"), systemImage: "tablecells")
                }
            }

            Section(L10n.text("summary.export_text")) {
                Text(trip.shareReport)
                    .font(.footnote)
                    .textSelection(.enabled)
            }
        }
        .listStyle(.insetGrouped)
        .travelListSurface()
        .navigationTitle(L10n.text("summary.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Currency calculator

struct CurrencyConverterView: View {
    @State private var amountText = "100"
    @State private var sourceCurrency = "USD"
    @State private var targetCurrency = "EUR"
    @State private var quoteState: ExchangeRateLoadState = .idle

    private var amount: Decimal? {
        MoneyFormatter.decimal(from: amountText)
    }

    private var quote: ExchangeRateQuote? {
        guard case let .loaded(quote) = quoteState else { return nil }
        return quote
    }

    private var convertedAmount: Decimal? {
        guard let amount, let quote, amount >= 0 else { return nil }
        return amount * quote.rate
    }

    var body: some View {
        Form {
            Section(L10n.text("converter.section_title")) {
                TextField(L10n.text("converter.amount"), text: $amountText)
                    .keyboardType(.decimalPad)

                Picker(L10n.text("converter.from"), selection: $sourceCurrency) {
                    ForEach(ExchangeRateTable.supportedCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }

                Picker(L10n.text("converter.to"), selection: $targetCurrency) {
                    ForEach(ExchangeRateTable.supportedCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }

                Button {
                    swapCurrencies()
                } label: {
                    Label(L10n.text("converter.swap"), systemImage: "arrow.left.arrow.right")
                }
            }

            Section {
                quoteContent
            } header: {
                Text(L10n.text("converter.rate_header"))
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text("converter.footer"))
                    Link(L10n.text("converter.provider"), destination: URL(string: "https://www.exchangerate-api.com")!)
                }
            }

            Section(L10n.text("converter.result")) {
                if let convertedAmount {
                    LabeledContent(L10n.text("converter.will_receive")) {
                        Text(MoneyFormatter.string(convertedAmount, currencyCode: targetCurrency))
                            .fontWeight(.semibold)
                    }
                } else {
                    Text(L10n.text("converter.invalid_amount"))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .travelListSurface()
        .navigationTitle(L10n.text("tool.convert_currency"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(sourceCurrency)-\(targetCurrency)") {
            await loadRate()
        }
    }

    private func swapCurrencies() {
        let previousSource = sourceCurrency
        sourceCurrency = targetCurrency
        targetCurrency = previousSource
    }

    @ViewBuilder
    private var quoteContent: some View {
        switch quoteState {
        case .idle, .loading:
            HStack {
                ProgressView()
                Text(L10n.text("converter.loading_rate"))
                    .foregroundStyle(.secondary)
            }

        case let .loaded(quote):
            LabeledContent("1 \(quote.sourceCurrency)") {
                Text("\(formattedRate(quote.rate)) \(quote.targetCurrency)")
                    .fontWeight(.semibold)
            }

            LabeledContent(L10n.text("converter.updated_at")) {
                Text(quote.updatedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await loadRate()
                }
            } label: {
                Label(L10n.text("converter.refresh"), systemImage: "arrow.clockwise")
            }

        case let .failed(message):
            Label(message, systemImage: "wifi.exclamationmark")
                .foregroundStyle(.red)

            Button {
                Task {
                    await loadRate()
                }
            } label: {
                Label(L10n.text("converter.retry"), systemImage: "arrow.clockwise")
            }
        }
    }

    private func formattedRate(_ rate: Decimal) -> String {
        rate.formatted(.number.precision(.fractionLength(2...6)))
    }

    private func loadRate() async {
        let source = sourceCurrency
        let target = targetCurrency

        if source == target {
            quoteState = .loaded(
                ExchangeRateQuote(
                    sourceCurrency: source,
                    targetCurrency: target,
                    rate: 1,
                    updatedAt: Date()
                )
            )
            return
        }

        quoteState = .loading

        do {
            let quote = try await ExchangeRateClient.fetchRate(from: source, to: target)
            guard !Task.isCancelled, source == sourceCurrency, target == targetCurrency else {
                return
            }
            quoteState = .loaded(quote)
        } catch is CancellationError {
            return
        } catch {
            guard source == sourceCurrency, target == targetCurrency else { return }
            quoteState = .failed(L10n.text("converter.request_failed"))
        }
    }
}

private enum ExchangeRateLoadState: Equatable {
    case idle
    case loading
    case loaded(ExchangeRateQuote)
    case failed(String)
}

private struct ExchangeRateQuote: Equatable, Sendable {
    let sourceCurrency: String
    let targetCurrency: String
    let rate: Decimal
    let updatedAt: Date
}

private nonisolated struct ExchangeRateResponse: Decodable, Sendable {
    let result: String
    let baseCode: String
    let timeLastUpdateUnix: TimeInterval
    let rates: [String: Decimal]

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case timeLastUpdateUnix = "time_last_update_unix"
        case rates
    }
}

private enum ExchangeRateClient {
    nonisolated static func fetchRate(
        from sourceCurrency: String,
        to targetCurrency: String
    ) async throws -> ExchangeRateQuote {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/\(sourceCurrency)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let payload = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        guard payload.result == "success",
              payload.baseCode == sourceCurrency,
              let rate = payload.rates[targetCurrency],
              rate > 0 else {
            throw URLError(.cannotParseResponse)
        }

        return ExchangeRateQuote(
            sourceCurrency: sourceCurrency,
            targetCurrency: targetCurrency,
            rate: rate,
            updatedAt: Date(timeIntervalSince1970: payload.timeLastUpdateUnix)
        )
    }
}
