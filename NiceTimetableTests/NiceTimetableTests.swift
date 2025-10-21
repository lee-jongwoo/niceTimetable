//
//  NiceTimetableTests.swift
//  NiceTimetableTests
//
//  Created by 이종우 on 10/21/25.
//

import Testing
@testable import NiceTimetable

struct APITests {
    let school = School(schoolType: "고등학교", schoolCode: "7010197", schoolName: "세화고등학교", officeCode: "B10", officeName: "", address: "")

    @Test func fetchSchools() async throws {
        let schools: [School] = try await NEISAPIClient.shared.searchSchools(for: "세화", type: "고등학교")
        #expect(schools.isEmpty == false)
    }

    @Test func fetchClasses() async throws {
        let classes: [SchoolClass] = try await NEISAPIClient.shared.fetchClasses(in: school)
        #expect(classes.isEmpty == false)
    }

    @Test func fetchTimetable() async throws {
        let weeklyTable: [TimetableDay] = try await NEISAPIClient.shared.fetchWeeklyTable(weekInterval: 0, disableCache: true)
        #expect(weeklyTable.isEmpty == false)
    }
}
