//
//  SchoolSearcher.swift
//  niceTimetable
//
//  Created by 이종우 on 10/9/25.
//

import Foundation
import SwiftUI

@Observable final class SchoolSearcher {
    var searchText: String = ""
    var schoolType: String = PreferencesManager.shared.schoolType ?? "고등학교"
    var schools: [School] = []
    var selectedSchool: School? = nil
    var classes: [SchoolClass] = []
    var selectedGrade: String = ""
    var selectedClass: String = ""
    
    func performSearch() async {
        guard !searchText.isEmpty else {
            schools = []
            return
        }
        do {
            let result = try await NEISAPIClient.shared.searchSchools(for: searchText, type: schoolType)
            withAnimation {
                self.schools = result
            }
        } catch {
            print("Error searching schools: \(error)")
            schools = []
        }
    }
    
    var isComplete: Bool {
        selectedSchool != nil && selectedGrade != "" && selectedClass != ""
    }
    
    func selectSchool(_ school: School) {
        self.selectedSchool = school
        self.classes = []
        self.selectedGrade = ""
        self.selectedClass = ""
        
        Task {
            self.classes = try await NEISAPIClient.shared.fetchClasses(in: school)
        }
    }
    
    func saveSchoolInfo() {
        guard let selectedSchool else { return }
        guard selectedGrade != "", selectedClass != "" else { return }
        PreferencesManager.shared.setSchoolInfo(school: selectedSchool, newClass: SchoolClass(grade: selectedGrade, className: selectedClass))
    }
}
