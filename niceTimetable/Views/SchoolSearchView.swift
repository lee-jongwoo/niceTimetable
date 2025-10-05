//
//  SchoolSearchView.swift
//  niceTimetable
//
//  Created by 이종우 on 10/1/25.
//

import SwiftUI

struct SchoolSearchView: View {
    @StateObject var viewModel = SchoolSearchViewModel()
    @Binding var schoolType: String
    @Binding var officeCode: String
    @Binding var schoolName: String
    @Binding var schoolCode: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            // Search schools by name and select one
            Picker("학교 유형", selection: $viewModel.schoolType) {
                Text("고등학교").tag("고등학교")
                Text("중학교").tag("중학교")
            }.pickerStyle(SegmentedPickerStyle())
            
            HStack {
                TextField("학교 이름으로 검색", text: $viewModel.searchText, onCommit: performSearch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                }
            }
            
            ForEach(viewModel.schools, id: \.schoolCode) { school in
                Button(action: {
                    schoolType = school.schoolType
                    officeCode = school.officeCode
                    schoolName = school.schoolName
                    schoolCode = school.schoolCode
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(school.schoolName)
                            Text(school.address).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if school.schoolCode == schoolCode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .navigationTitle("학교 검색")
    }
    
    func performSearch() {
        viewModel.searchSchools()
    }
}

#Preview {
    SchoolSearchView(schoolType: .constant("고등학교"), officeCode: .constant("B10"), schoolName: .constant("MySchool"), schoolCode: .constant("12345"))
}
