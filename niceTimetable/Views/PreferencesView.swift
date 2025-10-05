//
//  PreferencesView.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI
import WidgetKit

struct PreferencesView: View {
    @StateObject private var vm = PreferencesViewModel()
    @State var showingSchoolSearch = false
    
    var body: some View {
        List {
            // TODO: Replace with dropdown
            Section(header: Text("학교 정보"), footer: Text("학교별 기재 상태에 따라, 반 앞에 0이 붙을 수 있습니다. (예: 01반) 마음 같아서는 드롭다운으로 바꾸고 싶지만, 몹시 귀찮으므로 당분간은 이대로 갑니다.")) {
                Button(action: {
                    showingSchoolSearch = true
                }) {
                    HStack {
                        Text("학교 선택")
                            .foregroundColor(Color(UIColor.label))
                        Spacer()
                        if !vm.schoolName.isEmpty {
                            Text(vm.schoolName)
                        }
                    }
                }
                .sheet(isPresented: $showingSchoolSearch) {
                    NavigationView {
                        SchoolSearchView(schoolType: $vm.schoolType, officeCode: $vm.officeCode, schoolName: $vm.schoolName, schoolCode: $vm.schoolCode)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("취소") {
                                        showingSchoolSearch = false
                                    }
                                }
                            }
                    }
                }
                
                LabeledContent {
                    TextField("학년", text: $vm.grade)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("학년")
                }
                
                // TODO: 가끔 반 숫자 앞 0이 있는 경우가 있음. (ex: 01반)
                // 그래서 드롭다운에서 고르도록 바꿀 예정.
                LabeledContent {
                    TextField("반", text: $vm.className)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("반")
                }
                
                Button("저장") {
                    vm.save()
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .buttonSizing(.flexible)
            }
            
            Section(header: Text("과목 별칭"), footer: Text("과목 별칭을 추가하면 시간표에 표시되는 라벨을 변경할 수 있습니다.")) {
                NavigationLink("편집") {
                    AliasEditorView()
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

struct AboutView: View {
    var body: some View {
        List {
            Section(header: Text("앱 정보")) {
                LabeledContent("버전", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
                LabeledContent("빌드", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown")
                NavigationLink("고급") {
                    List {
                        Text("이 설정은 테스트 용도로 만들어 둔 것입니다. 뭐 건드려도 별일 없긴 합니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                        Section(header: Text("저장공간"), footer: Text("아마도 제 캐시 관리 로직이 알아서 필요없는 캐시를 비우겠지만, 찝찝하시면 수동으로 비우셔도 좋습니다.")) {
                            LabeledContent("캐시 크기") {
                                Text("\(CacheManager.shared.cacheSize)")
                            }
                            Button("캐시 비우기") {
                                CacheManager.shared.clearAll()
                            }
                        }
                        
                        Section(header: Text("위젯"), footer: Text("위젯을 강제로 새로고침합니다.")) {
                            Button("갱신") {
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
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

#Preview {
    NavigationStack {
        PreferencesView()
    }
}
