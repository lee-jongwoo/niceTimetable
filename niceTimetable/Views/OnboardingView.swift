//
//  OnboardingView.swift
//  niceTimetable
//
//  Created by 이종우 on 10/3/25.
//

import SwiftUI

struct OnboardingView: View {
    @State var tabSelection: Int = 0
    
    var body: some View {
        switch tabSelection {
        case 0:
            WelcomeView(tabSelection: $tabSelection)
        case 1:
            SetSchoolView()
        default:
            Text("Unknown Step")
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @Binding var tabSelection: Int
    var body: some View {
        VStack {
            Spacer()
            Text("\(Text("나이스시간표").foregroundStyle(Color("AccentColor")))에 오신 것을 환영합니다.")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            Spacer()
            
            VStack(spacing: 24) {
                FeatureCell(image: "square.grid.2x2", title: "우리 학교 시간표", subtitle: "번거로운 입력 없이, 학교와 반만 선택하면 자동으로 시간표를 불러옵니다.")
                FeatureCell(image: "widget.small", title: "위젯으로 한눈에", subtitle: "홈 화면과 잠금 화면에서 오늘의 시간표를 확인하세요.")
                FeatureCell(image: "star.square.on.square", title: "별칭으로 빠르게", subtitle: "알아보기 쉬운 별칭을 설정하여 시간표를 한눈에 파악하세요.")
            }
            .padding(.leading)
            
            Spacer()
            Spacer()
            
            Button(action: {
                withAnimation {
                    self.tabSelection = 1
                }
            }) {
                Text("계속")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
        }
        .padding()
    }
}

struct FeatureCell: View {
    var image: String
    var title: String
    var subtitle: String
    
    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32)
                .foregroundColor(Color("AccentColor"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}

struct SetSchoolView: View {
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    
    @State var searchQuery: String = ""
    @State var schoolType: String = "고등학교"
    @State var officeCode: String = ""
    @State var schoolName: String = ""
    @State var schoolCode: String = ""
    @State var grade: String = ""
    @State var className: String = ""
    @State var showingSchoolSearch = true
    
    @State var schools: [School] = []
    
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
                        TextField("입력", text: $grade)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    } label: {
                        Text("학년")
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    LabeledContent {
                        TextField("입력", text: $className)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
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
            
            if !schoolName.isEmpty && !grade.isEmpty && !className.isEmpty {
                Button(action: {
                    // Save to UserDefaults
                    let vm = PreferencesManager.shared
                    vm.schoolType = schoolType
                    vm.officeCode = officeCode
                    vm.schoolName = schoolName
                    vm.schoolCode = schoolCode
                    vm.grade = grade
                    vm.className = className
                    withAnimation {
                        self.isOnboarding = false
                    }
                }) {
                    Text("시작하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
            }
        }
        .padding()
        .animation(.default, value: className.isEmpty)
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
}

#Preview {
    SetSchoolView()
}
