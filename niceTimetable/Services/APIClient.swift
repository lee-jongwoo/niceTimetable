//
//  APIClient.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import Foundation

// MARK: - Error Types
enum NetworkingError: Error {
    case encodingFailed(innerError: EncodingError)
    case decodingFailed(innerError: DecodingError)
    case invalidStatusCode(statusCode: Int)
    case requestFailed(innerError: URLError)
    case otherError(innerError: Error)
}

// A service for fetching timetables from NEIS
final class NEISAPIClient {
    static let shared = NEISAPIClient()
    private init() {}
    
    // 원래는 따로 빼서 유출되지 않도록 해야 되는데,
    // 혹시라도 오픈소스 개발에 참여할 여러분의 수고를 덜기 위해
    // 걍 냅둡니다. 이걸로 나쁜 짓은 하지 말아 주세요.
    private let apiKey = "cbb9d435b84143d8aed60836da9cc6d3"
    
    // MARK: - School Search
    func searchSchools(for searchText: String, type: String) async throws -> [School] {
        do {
            var urlComponents = URLComponents(string: "https://open.neis.go.kr/hub/schoolInfo")!
            let parameters: [String: String] = [
                "KEY": apiKey,
                "Type": "json",
                "SCHUL_NM": searchText,
                "SCHUL_KND_SC_NM": type
            ]
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let url = urlComponents.url else {
                throw URLError(.badURL)
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                throw NetworkingError.invalidStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            
            let decoded = try JSONDecoder().decode(SchoolSearchAPIResponse.self, from: data)
            let rows = decoded.schoolInfo.flatMap { $0.row ?? [] }
            let schools = rows.toSchools()
            return schools
        } catch let encodingError as EncodingError {
            throw NetworkingError.encodingFailed(innerError: encodingError)
        } catch let decodingError as DecodingError {
            throw NetworkingError.decodingFailed(innerError: decodingError)
        } catch let urlError as URLError {
            throw NetworkingError.requestFailed(innerError: urlError)
        } catch {
            throw NetworkingError.otherError(innerError: error)
        }
    }
    
    // MARK: - Class Fetching
    func fetchClasses(in selectedSchool: School) async throws -> [SchoolClass] {
        do {
            let academicYear = String(Calendar.current.component(.year, from: Date()))
            var urlComponents = URLComponents(string: "https://open.neis.go.kr/hub/classInfo")!
            let parameters: [String: String] = [
                "KEY": apiKey,
                "Type": "json",
                "ATPT_OFCDC_SC_CODE": selectedSchool.officeCode,
                "SD_SCHUL_CODE": selectedSchool.schoolCode,
                "AY": academicYear
            ]
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let url = urlComponents.url else {
                throw URLError(.badURL)
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                throw NetworkingError.invalidStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            
            let decoded = try JSONDecoder().decode(ClassListAPIResponse.self, from: data)
            let rows = decoded.classInfo.flatMap { $0.row ?? [] }
            let classes = rows.toClasses()
            return classes
        } catch let encodingError as EncodingError {
            throw NetworkingError.encodingFailed(innerError: encodingError)
        } catch let decodingError as DecodingError {
            throw NetworkingError.decodingFailed(innerError: decodingError)
        } catch let urlError as URLError {
            throw NetworkingError.requestFailed(innerError: urlError)
        } catch {
            throw NetworkingError.otherError(innerError: error)
        }
    }
    
    // MARK: - Timetable Fetching
    func fetchTimetable(
        schoolType: String,
        officeCode: String,
        schoolCode: String,   // SD_SCHUL_CODE
        grade: String,
        className: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [TimetableDay] {
        do {
            // Format dates (yyyyMMdd)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            
            // Build query params
            let baseURL = (schoolType == "고등학교") ? "https://open.neis.go.kr/hub/hisTimetable" : "https://open.neis.go.kr/hub/misTimetable"
            var urlComponents = URLComponents(string: baseURL)!
            let parameters: [String: String] = [
                "KEY": apiKey,
                "Type": "json",
                "ATPT_OFCDC_SC_CODE": officeCode,
                "SD_SCHUL_CODE": schoolCode,
                "AY": String(Calendar.current.component(.year, from: startDate)),
                "GRADE": grade,
                "CLASS_NM": className,
                "TI_FROM_YMD": start,
                "TI_TO_YMD": end
            ]
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let url = urlComponents.url else {
                throw URLError(.badURL)
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                throw NetworkingError.invalidStatusCode(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            
            let decoded = try JSONDecoder().decode(NEISAPIResponse.self, from: data)
            let rows = decoded.hisTimetable.flatMap { $0.row ?? [] }
            // Map to days
            let days = rows.toTimetableDays()
            if days.isEmpty {
                throw NSError(domain: "NEISAPIClient", code: 2, userInfo: [NSLocalizedDescriptionKey: "해당 기간에 수업이 없습니다."])
            }
            // Insert empty days for missing weekdays in the requested range (e.g., holidays)
            let padded = self.padDays(days, from: startDate, to: endDate)
            return padded
        } catch let encodingError as EncodingError {
            throw NetworkingError.encodingFailed(innerError: encodingError)
        } catch let decodingError as DecodingError {
            throw NetworkingError.decodingFailed(innerError: decodingError)
        } catch let urlError as URLError {
            throw NetworkingError.requestFailed(innerError: urlError)
        } catch {
            throw NetworkingError.otherError(innerError: error)
        }
    }
    
    // MARK: - Batch Fetching
    func fetchCachedWeeklyTable(weekInterval: Int = 0) -> [TimetableDay]? {
        let baseDate = Date().addingTimeInterval(TimeInterval(weekInterval * 7 * 24 * 60 * 60))
        // Find Monday
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: baseDate))!
        let weekKey = startOfWeek.weekIdentifier()
        return CacheManager.shared.get(for: weekKey, maxAge: 2 * 60 * 60)
    }
        
    func fetchWeeklyTable(
        weekInterval: Int = 0,
        disableCache: Bool = false
    ) async throws -> [TimetableDay] {
        guard
            let schoolType = PreferencesManager.shared.schoolType,
            let officeCode = PreferencesManager.shared.officeCode,
            let schoolCode = PreferencesManager.shared.schoolCode,
            let grade = PreferencesManager.shared.grade,
            let className = PreferencesManager.shared.className
        else {
            throw NSError(domain: "NEISAPIClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "학교 정보가 설정되지 않았습니다."])
        }
        
        let baseDate = Date().addingTimeInterval(TimeInterval(weekInterval * 7 * 24 * 60 * 60))
        
        // Find Monday
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: baseDate))!
        // Find Friday
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 5, to: startOfWeek)!
        
        // Check cache first
        let weekKey = startOfWeek.weekIdentifier()
        if !disableCache, let cached = CacheManager.shared.get(for: weekKey, maxAge: 2 * 60 * 60) {
            return cached
        }
        
        let result = try await NEISAPIClient.shared.fetchTimetable(
            schoolType: schoolType,
            officeCode: officeCode,
            schoolCode: schoolCode,
            grade: grade,
            className: className,
            startDate: startOfWeek,
            endDate: endOfWeek
        )
        // Cache the result
        CacheManager.shared.set(result, for: weekKey)
        return result
    }
    
    // Fill missing weekdays between start and end with empty TimetableDay entries
    private func padDays(_ days: [TimetableDay], from startDate: Date, to endDate: Date) -> [TimetableDay] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        
        // Index existing days by their normalized date
        var byDate: [Date: TimetableDay] = [:]
        for d in days {
            byDate[cal.startOfDay(for: d.date)] = d
        }
        
        var result: [TimetableDay] = []
        var cursor = start
        while cursor <= end {
            let weekday = cal.component(.weekday, from: cursor)
            // Monday(2) ... Friday(6)
            if (2...6).contains(weekday) {
                if let existing = byDate[cursor] {
                    result.append(existing)
                } else {
                    result.append(TimetableDay(date: cursor, columns: []))
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        
        return result.sorted { $0.date < $1.date }
    }
}
