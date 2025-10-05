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
    let head: [SchoolHead]?
    let row: [SchoolRow]?
}

struct SchoolHead: Codable {
    let list_total_count: Int?
    let RESULT: SchoolResult?
}

struct SchoolResult: Codable {
    let CODE: String
    let MESSAGE: String
}

struct SchoolRow: Codable {
    let ATPT_OFCDC_SC_CODE: String   // 교육청 코드
    let ATPT_OFCDC_SC_NM: String     // 교육청명
    let SD_SCHUL_CODE: String        // 학교 코드
    let SCHUL_NM: String             // 학교명
    let ENG_SCHUL_NM: String?        // 영문 학교명
    let SCHUL_KND_SC_NM: String      // 학교 종류 (초등학교, 중학교, 고등학교 등)
    let LCTN_SC_NM: String           // 소재지 시도명
    let JU_ORG_NM: String            // 관할 교육지원청명
    let FOND_SC_NM: String           // 설립 구분 (공립, 사립 등)
    let ORG_RDNZC: String?           // 우편번호
    let ORG_RDNMA: String?           // 도로명 주소
    let ORG_RDNDA: String?           // 도로명 상세 주소
    let ORG_TELNO: String?           // 전화번호
    let HMPG_ADRES: String?          // 홈페이지 주소
    let COEDU_SC_NM: String?         // 남녀공학 구분 (남, 여, 공)
    let ORG_FAXNO: String?           // 팩스번호
    let HS_SC_NM: String?            // 고등학교 구분 (일반
    let INDST_SPECL_CCCCL_EXST_YN: String? // 특성화고 여부 (Y/N)
    let HS_GNRL_BUSNS_SC_NM: String? // 일반고 직업교육 가능 여부
    let SPCLY_PURPS_HS_ORD_NM: String?
    let ENE_BFE_SEHF_SC_NM: String?
    let DGHT_SC_NM: String?
    let FOND_YMD: String?            // 설립 연월일
    let FOAS_MEMRD: String?          // 설립자
    let LOAD_DTM: String?            // 수정일
}

// MARK: - Class List API Response
struct ClassListAPIResponse: Codable {
    let classInfo: [ClassContainer]
}

struct ClassContainer: Codable {
    let head: [ClassHead]?
    let row: [ClassRow]?
}

struct ClassHead: Codable {
    let list_total_count: Int?
    let RESULT: ClassResult?
}

struct ClassResult: Codable {
    let CODE: String
    let MESSAGE: String
}

struct ClassRow: Codable {
    let ATPT_OFCDC_SC_CODE: String   // 교육청 코드
    let ATPT_OFCDC_SC_NM: String     // 교육청명
    let SD_SCHUL_CODE: String        // 학교 코드
    let SCHUL_NM: String             // 학교명
    let AY: String                   // 학년도
    let GRADE: String                // 학년
    let CLASS_NM: String             // 반
    let LOAD_DTM: String?            // 수정일
}

// MARK: - Timetable API Response

// Root NEIS timetable response
struct NEISAPIResponse: Decodable {
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
    let head: [NEISHead]?
    let row: [NEISRow]?
}

// "head" metadata
struct NEISHead: Codable {
    let list_total_count: Int?
    let RESULT: NEISResult?
}

struct NEISResult: Codable {
    let CODE: String
    let MESSAGE: String
}

// "row" = actual timetable rows
struct NEISRow: Codable {
    let ATPT_OFCDC_SC_CODE: String   // 교육청 코드
    let ATPT_OFCDC_SC_NM: String     // 교육청명
    let SD_SCHUL_CODE: String        // 학교 코드
    let SCHUL_NM: String             // 학교명
    let AY: String                   // 학년도
    let SEM: String                  // 학기
    let ALL_TI_YMD: String           // YYYYMMDD (수업일자)
    let GRADE: String                // 학년
    let CLASS_NM: String             // 반
    let PERIO: String                // 교시
    let ITRT_CNTNT: String           // 과목명
    let CLRM_NM: String?             // 교실명 (있을 경우)
    let LOAD_DTM: String?            // 수정일
}
