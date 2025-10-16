//
//  APIResponse.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import Foundation

// MARK: - School Search API Response
struct SchoolSearchAPIResponse: Codable {
    let schoolInfo: [SchoolContainer]
}

struct SchoolContainer: Codable {
    let row: [SchoolRow]?
}

struct SchoolRow: Codable {
    let officeCode: String  // 교육청 코드
    let officeName: String  // 교육청명
    let schoolCode: String  // 학교 코드
    let schoolName: String  // 영문 학교명
    let schoolType: String  // 학교 종류 (초등학교, 중학교, 고등학교 등)
    let address: String?    // 도로명 주소자
    let loadDate: String?   // 수정일

    enum CodingKeys: String, CodingKey {
        case officeCode = "ATPT_OFCDC_SC_CODE"
        case officeName = "ATPT_OFCDC_SC_NM"
        case schoolCode = "SD_SCHUL_CODE"
        case schoolName = "SCHUL_NM"
        case schoolType = "SCHUL_KND_SC_NM"
        case address = "ORG_RDNMA"
        case loadDate = "LOAD_DTM"
    }
}

// MARK: - Class List API Response
struct ClassListAPIResponse: Codable {
    let classInfo: [ClassContainer]
}

struct ClassContainer: Codable {
    let row: [ClassRow]?
}

struct ClassRow: Codable {
    let officeCode: String      // 교육청 코드
    let officeName: String      // 교육청명
    let schoolCode: String      // 학교 코드
    let schoolName: String      // 학교명
    let academicYear: String    // 학년도
    let grade: String           // 학년
    let className: String       // 반
    let loadDate: String?       // 수정일

    enum CodingKeys: String, CodingKey {
        case officeCode = "ATPT_OFCDC_SC_CODE"
        case officeName = "ATPT_OFCDC_SC_NM"
        case schoolCode = "SD_SCHUL_CODE"
        case schoolName = "SCHUL_NM"
        case academicYear = "AY"
        case grade = "GRADE"
        case className = "CLASS_NM"
        case loadDate = "LOAD_DTM"
    }
}

// MARK: - Timetable API Response

// Root NEIS timetable response
struct NEISAPIResponse: Decodable, Sendable {
    let hisTimetable: [TimetableContainer]

    private enum CodingKeys: String, CodingKey {
        case hisTimetable
        case misTimetable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let his = try container.decodeIfPresent([TimetableContainer].self, forKey: .hisTimetable) {
            self.hisTimetable = his
        } else if let mis = try container.decodeIfPresent([TimetableContainer].self, forKey: .misTimetable) {
            self.hisTimetable = mis
        } else {
            self.hisTimetable = []
        }
    }
}

// NEIS gives either "head" or "row"
struct TimetableContainer: Codable {
    let row: [NEISRow]?
}

// "row" = actual timetable rows
struct NEISRow: Codable {
    let date: String            // YYYYMMDD (수업일자)
    let className: String       // 반
    let period: String          // 교시
    let subject: String         // 과목명
    let room: String?           // 교실명 (있을 경우)
    let lastUpdated: String?    // 수정일

    enum CodingKeys: String, CodingKey {
        case date = "ALL_TI_YMD"
        case className = "CLASS_NM"
        case period = "PERIO"
        case subject = "ITRT_CNTNT"
        case room = "CLRM_NM"
        case lastUpdated = "LOAD_DTM"
    }
}
