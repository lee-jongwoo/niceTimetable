//
//  SchoolSearchViewModel.swift
//  niceTimetable
//
//  Created by 이종우 on 10/1/25.
//

import Foundation
import Combine

@MainActor
class SchoolSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var schoolType: String = PreferencesManager.shared.schoolType ?? "고등학교"
    @Published var schools: [School] = []
    
    func searchSchools() {
        NEISAPIClient.shared.fetchSchoolList(schoolName: searchText, schoolType: schoolType) { result in
            switch result {
            case .success(let schools):
                self.schools = schools
            case .failure(let error):
                print("Error fetching schools: \(error)")
                self.schools = []
            }
        }
    }
}
