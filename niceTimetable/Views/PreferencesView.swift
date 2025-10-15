//
//  PreferencesView.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI

struct PreferencesView: View {
    @State var showingSchoolSearch = false
    @AppStorage("schoolName", store: .appGroup) private var schoolName: String = ""
    @AppStorage("grade", store: .appGroup) private var grade: String = ""
    @AppStorage("className", store: .appGroup) private var className: String = ""
    @AppStorage("daySwitchTime", store: .appGroup) private var daySwitchTime: String = ""
    
    var body: some View {
        List {
            Section {
                LabeledContent("학교") {
                    Text(schoolName)
                }
                LabeledContent("학년") {
                    Text(grade)
                }
                LabeledContent("반") {
                    Text(className)
                }
                Button {
                    showingSchoolSearch = true
                } label: {
                    Label("변경하기", systemImage: "pencil")
                }
                .sheet(isPresented: $showingSchoolSearch) {
                    NavigationStack {
                        SetSchoolView(isWelcomeScreen: false)
                    }
                }
            }
            
            Section {
                // Set when to switch days:
                // After this time of day, the next day is shown by default
                NavigationLink(destination: DateChangeTimeView()) {
                    Text("다음 날 보기")
                        .badge("\(self.daySwitchTime != "00:00" ? "\(self.daySwitchTime) 이후" : "끔")")
                }
            }
            
            Section("정보") {
                NavigationLink("이 앱에 관하여...") {
                    AboutView()
                }
                Link(destination: URL(string: "https://apps.apple.com/app/id6753567120?action=write-review")!) {
                    Label("앱 평가하기", systemImage: "star.bubble")
                }
                Link(destination: URL(string: "mailto:jongwoo@jongwoo.dev")!) {
                    Label("문의/버그 신고", systemImage: "envelope")
                }
            }
        }
        .navigationTitle("설정")
    }
}

struct DateChangeTimeView: View {
    @State private var isDaySwitchOn: Bool = PreferencesManager.shared.isDaySwitchTimeOn
    @State private var daySwitchTime: (hour: Int, minute: Int) = PreferencesManager.shared.daySwitchTime

    var body: some View {
        Form {
            Section(footer: Text("전환 시각 이후로 앱과 위젯에서 다음 날의 시간표를 보여줍니다.")) {
                Toggle("다음 날 보기", isOn: $isDaySwitchOn)
                    .onChange(of: isDaySwitchOn) { _, new in
                        if new == false {
                            PreferencesManager.shared.daySwitchTime = (0, 0)
                            print("Reset day switch time")
                            PreferencesManager.shared.shouldUpdateWidget = true
                        }
                    }
                if isDaySwitchOn {
                    DatePicker("전환 시각", selection: Binding(
                        get: {
                            let components = DateComponents(hour: daySwitchTime.hour, minute: daySwitchTime.minute)
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            if let hour = components.hour, let minute = components.minute {
                                daySwitchTime = (hour, minute)
                                PreferencesManager.shared.daySwitchTime = daySwitchTime
                                print("Set day switch time to \(daySwitchTime.hour):\(daySwitchTime.minute)")
                                PreferencesManager.shared.shouldUpdateWidget = true
                            }
                        }
                    ), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }
            }
        }
        .navigationTitle("다음 날 보기")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section(header: Text("앱 정보")) {
                LabeledContent("버전", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
                LabeledContent("빌드", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")
                NavigationLink("고급") {
                    AdvancedInfoView()
                }
            }
            
            Section(header: Text("개발자")) {
                Text("""
                    이 앱을 만든 사람(들)
                    - lee-jongwoo (jongwoo@jongwoo.dev)
                    
                    아직 저 말고는 목록에 사람이 없네요.
                    이 앱은 오픈 소스로 공개되어 있습니다. 혹시 SwiftUI 개발에 관심이 있으시다면, [GitHub](https://github.com/lee-jongwoo/niceTimetable)에서 niceTimetable 레포지토리를 확인해 보세요. PR 언제나 환영입니다.
                    """)
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Section(header: Text("라이선스")) {
                Text("""
                    이 앱은 외부 오픈 소스 라이브러리를 사용하지 않았습니다.
                    라이선스는 MIT 라이선스입니다.
                    """)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("정보")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdvancedInfoView: View {
    @AppStorage("schoolType", store: .appGroup) private var schoolType: String = "고등학교"
    @AppStorage("officeCode", store: .appGroup) private var officeCode: String = ""
    @AppStorage("schoolName", store: .appGroup) private var schoolName: String = ""
    @AppStorage("schoolCode", store: .appGroup) private var schoolCode: String = ""
    @AppStorage("grade", store: .appGroup) private var grade: String = ""
    @AppStorage("className", store: .appGroup) private var className: String = ""
    
    var body: some View {
        Form {
            Text("이 설정은 테스트 용도로 만들어 둔 것입니다. 뭐 건드려도 별일 없긴 합니다.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Section(header: Text("학교 정보"), footer: Text("이 설정은 바꾼 다음 자동으로 반영되지 않을 수 있어요. 설정을 완료하면 캐시를 비우고 앱을 재시작해주세요.")) {
                Picker("학교 유형", selection: $schoolType) {
                    Text("고등학교").tag("고등학교")
                    Text("중학교").tag("중학교")
                }
                
                LabeledContent {
                    TextField("교육청 코드", text: $officeCode)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("교육청 코드")
                }
                
                LabeledContent {
                    TextField("학교 이름", text: $schoolName)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("학교 이름")
                }
                
                LabeledContent {
                    TextField("학교 코드", text: $schoolCode)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("학교 코드")
                }
                
                LabeledContent {
                    TextField("학년", text: $grade)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("학년")
                }
                
                LabeledContent {
                    TextField("반", text: $className)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("반")
                }
            }
            
            Section(header: Text("저장공간"), footer: Text("아마도 제 캐시 관리 로직이 알아서 필요없는 캐시를 비우겠지만, 찝찝하시면 수동으로 비우셔도 좋습니다.")) {
                NavigationLink("과목 별칭...") {
                    AliasEditorView()
                }
                LabeledContent("캐시 크기") {
                    Text("\(CacheManager.shared.cacheSize)")
                }
                Button("캐시 비우기") {
                    CacheManager.shared.clearAll()
                }
            }
            
            Section(header: Text("위젯"), footer: Text("위젯을 강제로 새로고침합니다.")) {
                Button("갱신") {
                    CacheManager.shared.reloadWidgets()
                }
            }
        }
        .navigationTitle("고급")
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }
}
