//
//  SchoolModels.swift
//  niceTimetable
//
//  Created by 이종우 on 10/1/25.
//

import Foundation

struct School: Identifiable, Codable, Equatable {
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

struct SchoolClass: Identifiable, Codable {
    var id: String { grade + className }
    let grade: String
    let className: String
}

// MARK: - Extensions

// Convert to School List
extension Array where Element == SchoolRow {
    func toSchools() -> [School] {
        let rows = self.map { row in
            School(
                schoolType: row.schoolType,
                schoolCode: row.schoolCode,
                schoolName: row.schoolName,
                officeCode: row.officeCode,
                officeName: row.officeName,
                address: row.address ?? "주소 없음",
                type: row.schoolType
            )
        }
        // Remove duplicates by schoolCode
        let schools = Dictionary(grouping: rows, by: { $0.schoolCode }).compactMap { $0.value.first }
        // Sort by address first, then name
        return schools.sorted {
            if $0.officeCode == $1.officeCode {
                return $0.schoolName < $1.schoolName
            } else {
                return $0.officeCode < $1.officeCode
            }
        }
    }
}

// Convert to Class List
extension Array where Element == ClassRow {
    func toClasses() -> [SchoolClass] {
        let classes = self.map { row in
            SchoolClass(
                grade: row.grade,
                className: row.className
            )
        }
        // Remove duplicates by grade+className
        let uniqueClasses = Dictionary(grouping: classes, by: { $0.grade + $0.className }).compactMap { $0.value.first }
        // Sort by grade then className (numerically if possible)
        return uniqueClasses.sorted {
            if $0.grade == $1.grade {
                // Try numeric comparison for className
                if let num1 = Int($0.className), let num2 = Int($1.className) {
                    return num1 < num2
                } else {
                    return $0.className < $1.className
                }
            } else {
                // Try numeric comparison for grade
                if let g1 = Int($0.grade), let g2 = Int($1.grade) {
                    return g1 < g2
                } else {
                    return $0.grade < $1.grade
                }
            }
        }
    }
}

extension String {
    var firstMeaningfulCharacter: Character? {
        let allowed = CharacterSet.letters.union(.decimalDigits)
        return self.first { char in
            char.unicodeScalars.allSatisfy { allowed.contains($0) }
        }
    }
}
