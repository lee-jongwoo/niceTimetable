//
//  TimetableDetailsView.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI
import StoreKit

struct TimetableDetailsView: View {
    @EnvironmentObject var aliasStore: AliasStore
    let column: TimetableColumn

    @State private var aliasLong: String = ""
    @State private var aliasShort: String = ""
    @State private var currentDetent: PresentationDetent = .medium
    @Environment(\.dismiss) private var dismiss
    @AppStorage("aliasSetCount") private var aliasSetCount: Int = 0
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("별칭"), footer: Text("별칭은 앱과 큰 위젯에서 과목명을 대체합니다.")) {
                    TextField(String(column.subject), text: $aliasLong, onEditingChanged: { began in
                        // SwiftUI bug: detent won't change when sheet expands due to keyboard appearing
                        if began {
                            currentDetent = .large
                        }
                    })
                }

                Section(header: Text("이니셜"), footer: Text("작은 화면에서는 별칭 대신 한 글자의 이니셜이 사용됩니다.")) {
                    TextField(
                        String(aliasLong.firstMeaningfulCharacter.map { String($0) } ?? column.subject.firstMeaningfulCharacter.map { String($0) } ?? ""),
                        text: $aliasShort,
                        onEditingChanged: { began in
                            if began {
                                currentDetent = .large
                            }
                        }
                    )
                }

                Section(header: Text("상세 정보")) {
                    LabeledContent("교시", value: "\(column.period)교시")
                    LabeledContent("과목명", value: column.subject)
                    LabeledContent("교실", value: column.room ?? "정보 없음")
                    LabeledContent("수정일", value: column.lastUpdated ?? "정보 없음")
                }
            }
            .onAppear {
                if let alias = aliasStore.aliases[column.subject] {
                    aliasLong = alias.normal
                    aliasShort = alias.compact
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", systemImage: "checkmark") {
                        aliasStore.setAlias(
                            for: column.subject,
                            normal: aliasLong,
                            compact: String(aliasShort.prefix(1))
                        )
                        aliasSetCount += 1
                        dismiss()

                        if aliasSetCount == 5 {
                            requestReview()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(aliasLong == aliasStore.aliases[column.subject]?.normal ?? "" && aliasShort == aliasStore.aliases[column.subject]?.compact ?? "")
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .modify {
                if #available(iOS 26, *) {
                    $0.scrollContentBackground(
                        currentDetent == .medium ? .hidden : .automatic
                    )
                } else {
                    $0
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $currentDetent)
        .animation(.default, value: currentDetent)
    }
}

#Preview {
}
