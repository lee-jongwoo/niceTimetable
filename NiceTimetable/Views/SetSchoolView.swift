//
//  SetSchoolView.swift
//  niceTimetable
//
//  Created by 이종우 on 10/10/25.
//

import SwiftUI

struct SetSchoolView: View {
    let isWelcomeScreen: Bool
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    @State private var model = SchoolSearcher()
    @State var showingSchoolSearch = true
    @Environment(\.dismiss) var dismiss

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
                    Picker("학교 유형", selection: $model.schoolType) {
                        Text("고등학교").tag("고등학교")
                        Text("중학교").tag("중학교")
                    }.pickerStyle(SegmentedPickerStyle())
                    HStack {
                        TextField("학교 이름으로 검색...", text: $model.searchText)
                            .onSubmit {
                                Task {
                                    await model.performSearch()
                                }
                            }
                            .submitLabel(.go)
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color("AccentColor"))
                            .onTapGesture {
                                Task {
                                    await model.performSearch()
                                }
                            }
                    }
                    .padding()
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                    ForEach(model.schools, id: \.schoolCode) { school in
                        Divider()
                        Button(action: {
                            model.selectSchool(school)
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
                                if model.selectedSchool?.schoolCode == school.schoolCode {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding(5)
                        }
                    }
                } else {
                    Divider()
                    HStack {
                        Text(model.selectedSchool?.schoolName ?? "선택된 학교 없음")
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

            if model.selectedSchool != nil {
                VStack {
                    HStack {
                        Text("학급 선택")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }

                    LabeledContent {
                        Picker("학년", selection: $model.selectedGrade) {
                            Text("선택").tag("")
                            let grades = Array(Set(model.classes.map { $0.grade })).sorted()
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
                        Picker("반", selection: $model.selectedClass) {
                            Text("선택").tag("")
                            let classNames = model.classes.filter { $0.grade == model.selectedGrade }.map { $0.className }
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

            Spacer()

            if model.isComplete {
                Button(action: {
                    // Save to UserDefaults
                    model.saveSchoolInfo()
                    if isWelcomeScreen {
                        withAnimation {
                            self.isOnboarding = false
                        }
                    } else {
                        // Dismiss the view
                        dismiss()
                        CacheManager.shared.clearAll()
                    }
                }) {
                    Text(isWelcomeScreen ? "시작하기" : "저장하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.extraLarge)
                .modify {
                    if #available(iOS 26, *) {
                        $0.buttonStyle(.glassProminent)
                    } else {
                        $0.buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
        .animation(.default, value: model.selectedClass)
    }
}

// MARK: - Conditional View Modifier
public extension View {
    func modify(@ViewBuilder transform: (Self) -> some View) -> some View {
        transform(self)
    }
}

#Preview {
    SetSchoolView(isWelcomeScreen: true)
}
