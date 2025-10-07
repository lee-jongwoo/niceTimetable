//
//  AliasEditorView.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI

struct AliasEditorView: View {
    @State private var subject: String = ""
    @State private var normalAlias: String = ""
    @State private var compactAlias: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("새 별칭 추가"), footer: Text("시간표의 과목을 탭하면 표시되는 상세 화면에서도 별칭을 편집할 수 있습니다.")) {
                TextField("과목명", text: $subject)
                TextField("별칭", text: $normalAlias)
                TextField("이니셜", text: $compactAlias)
                Button("저장") {
                    guard !subject.isEmpty, !normalAlias.isEmpty, !compactAlias.isEmpty else { return }
                    PreferencesManager.shared.setAlias(for: subject, normal: normalAlias, compact: compactAlias)
                    subject = ""
                    normalAlias = ""
                    compactAlias = ""
                }
            }
            
            Section(header: Text("기존 별칭")) {
                let allAliases = PreferencesManager.shared.aliases.sorted { $0.key < $1.key }
                ForEach(allAliases, id: \.key) { subject, pair in
                    HStack {
                        Text(subject)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(pair.normal)
                            Text(pair.compact).font(.caption).foregroundColor(.secondary)
                        }
                        Button(role: .destructive) {
                            PreferencesManager.shared.removeAlias(for: subject)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("과목 별칭")
    }
}
