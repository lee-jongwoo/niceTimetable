//
//  SchoolModels.swift
//  niceTimetable
//
//  Created by 이종우 on 10/1/25.
//

import Foundation

struct School: Identifiable, Codable {
    var id: String { schoolCode }
    let schoolType: String
    let schoolCode: String
    let schoolName: String
    let officeCode: String
    let officeName: String
    let address: String
    
    // future-proof for potential addition of middle, elementary school support
    let type: String
}
