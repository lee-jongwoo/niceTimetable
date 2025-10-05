//
//  SchoolSearchView.swift
//  niceTimetable
//
//  Created by 이종우 on 10/1/25.
//

import SwiftUI

struct SchoolSearchView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var searchQuery: String = ""
    @State var schoolType: String = "고등학교"
    @State var officeCode: String = ""
    @State var schoolName: String = ""
    @State var schoolCode: String = ""
    @State var grade: String = ""
    @State var className: String = ""
    @State var showingSchoolSearch = true
    
    @State var schools: [School] = []
    @State var classes: [SchoolClass] = []
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("학교 선택")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Image(systemName: showingSchoolSearch ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        showingSchoolSearch = true
                    }
                }
                if showingSchoolSearch {
                    Picker("학교 유형", selection: $schoolType) {
                        Text("고등학교").tag("고등학교")
                        Text("중학교").tag("중학교")
                    }.pickerStyle(SegmentedPickerStyle())
                    HStack {
                        TextField("학교 이름으로 검색...", text: $searchQuery)
                            .onSubmit {
                                performSearch()
                            }
                            .submitLabel(.go)
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color("AccentColor"))
                            .onTapGesture {
                                performSearch()
                            }
                    }
                    .padding()
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                    ForEach(schools, id: \.schoolCode) { school in
                        Divider()
                        Button(action: {
                            officeCode = school.officeCode
                            schoolName = school.schoolName
                            schoolCode = school.schoolCode
                            findClasses()
                            withAnimation {
                                showingSchoolSearch = false
                            }
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
                            .padding(5)
                        }
                        
                    }
                } else {
                    Divider()
                    HStack {
                        Text(schoolName)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            
            if !schoolName.isEmpty {
                VStack {
                    HStack {
                        Text("학급 선택")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    LabeledContent {
                        Picker("학년", selection: $grade) {
                            Text("선택").tag("")
                            let grades = Array(Set(classes.map { $0.grade })).sorted()
                            ForEach(grades, id: \.self) { grade in
                                Text(grade).tag(grade)
                            }
                        }
                        .pickerStyle(.menu)
                    } label: {
                        Text("학년")
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    LabeledContent {
                        Picker("반", selection: $className) {
                            Text("선택").tag("")
                            let classNames = classes.filter { $0.grade == grade }.map { $0.className }
                            ForEach(classNames, id: \.self) { className in
                                Text(className).tag(className)
                            }
                        }
                        .pickerStyle(.menu)
                    } label: {
                        Text("반")
                    }
                    .padding(.vertical, 4)
                    
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .padding()
        .animation(.default, value: className.isEmpty)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소", systemImage: "xmark") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("저장", systemImage: "checkmark") {
                    // Save to UserDefaults
                    let vm = PreferencesManager.shared
                    vm.schoolType = schoolType
                    vm.officeCode = officeCode
                    vm.schoolName = schoolName
                    vm.schoolCode = schoolCode
                    vm.grade = grade
                    vm.className = className
                    dismiss()
                }
                .disabled(schoolName.isEmpty || grade.isEmpty || className.isEmpty)
                .buttonStyle(.borderedProminent)
            }
                
        }
    }
    
    func performSearch() {
        NEISAPIClient.shared.fetchSchoolList(schoolName: searchQuery, schoolType: schoolType) { result in
            switch result {
            case .success(let schools):
                withAnimation {
                    self.schools = schools
                }
            case .failure(let error):
                print("Error fetching schools: \(error)")
                self.schools = []
            }
        }
    }
    
    // TODO: Use some better async method
    func findClasses() {
        NEISAPIClient.shared.fetchClassList(officeCode: officeCode, schoolCode: schoolCode) { result in
            switch result {
            case .success(let classes):
                self.classes = classes
            case .failure(let error):
                print("Error fetching classes: \(error)")
                self.classes = []
            }
        }
    }
}

#Preview {
}
