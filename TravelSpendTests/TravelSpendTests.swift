//
//  TravelSpendTests.swift
//  TravelSpendTests
//
//  Created by sebastian alberto clark valenzuela on 09/08/26.
//

import Testing
import Foundation
@testable import TravelSpend

struct TravelSpendTests {

    @Test func calculatesDailyAllowanceAndProjection() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 10)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 14)))
        let checkDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 11)))

        let trip = Trip(
            destination: "Oaxaca",
            budget: 1_500,
            currencyCode: "MXN",
            startDate: start,
            endDate: end,
            expenses: [
                Expense(
                    title: "Hotel",
                    amount: 600,
                    category: .accommodation,
                    date: start
                )
            ]
        )

        #expect(trip.totalTripDays == 5)
        #expect(trip.daysElapsed(asOf: checkDate) == 2)
        #expect(trip.daysRemaining(asOf: checkDate) == 4)
        #expect(trip.dailyAllowance(asOf: checkDate) == 225)
        #expect(trip.projectedTotal(asOf: checkDate) == 1_500)
    }

    @Test func decodesTripsSavedBeforeCategoryPlanningWasAdded() throws {
        let oldTrip = """
        {
          "id": "F689E0B1-8377-4E29-80A7-DB3610A2D2D7",
          "destination": "Mérida",
          "budget": 2000,
          "currencyCode": "MXN",
          "startDate": "2026-08-10T00:00:00Z",
          "endDate": "2026-08-14T00:00:00Z",
          "createdAt": "2026-08-01T00:00:00Z",
          "isClosed": false,
          "expenses": []
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let trip = try decoder.decode(Trip.self, from: try #require(oldTrip.data(using: .utf8)))

        #expect(trip.categoryBudgets.isEmpty)
        #expect(trip.plannedTotal == 0)
    }

}
