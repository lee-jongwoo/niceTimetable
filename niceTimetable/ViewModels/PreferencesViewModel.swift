//
//  PreferencesViewModel.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import Foundation
import Combine
import WidgetKit

@MainActor
class PreferencesViewModel: ObservableObject {
    @Published var schoolType: String = ""
    @Published var officeCode: String = ""
    @Published var schoolName: String = ""
    @Published var schoolCode: String = ""
    @Published var grade: String = ""
    @Published var className: String = ""
    
    init() {
        load()
    }
    
    func load() {
        let prefs = PreferencesManager.shared
        schoolType = prefs.schoolType ?? "고등학교"
        officeCode = prefs.officeCode ?? ""
        schoolName = prefs.schoolName ?? ""
        schoolCode = prefs.schoolCode ?? ""
        grade = prefs.grade ?? ""
        className = prefs.className ?? ""
    }
    
    func save() {
        let prefs = PreferencesManager.shared
        prefs.schoolType = schoolType
        prefs.officeCode = officeCode
        prefs.schoolName = schoolName
        prefs.schoolCode = schoolCode
        prefs.grade = grade
        prefs.className = className
        
        // Remove cached timetable when school info changes
        CacheManager.shared.clearAll()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
