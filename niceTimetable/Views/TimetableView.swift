//
//  ContentView.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI

struct TimetableView: View {
    @StateObject private var model = TimetableViewModel()
    @StateObject private var aliasStore = AliasStore()

    var viewModes = ["작게", "크게"]
    @AppStorage("viewMode") private var viewMode: String = "작게"
    @State var selectedItem: TimetableColumn? = nil

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // I'm really sorry, but using NavigationTitle here is really buggy with those nested scroll views.
                Text("시간표")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(-5...3, id: \.self) { offset in
                            if let week = model.weeks[offset] {
                                TimetableGridView(week: week, selectedItem: $selectedItem)
                                    .environmentObject(aliasStore)
                                    .id(offset)
                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                                    .refreshable {
                                        await model.checkForUpdates(weekInterval: model.currentWeekIndex ?? 0)
                                    }
                            } else if let errorMsg = model.errorMessages[offset] {
                                VStack {
                                    if errorMsg == "tableNotRegistered" {
                                        Image(systemName: "info.circle")
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                        Text("시간표가 존재하지 않음")
                                            .font(.headline)
                                        Text("아직 학교에서 해당 기간의 시간표를 등록하지 않았을 수 있습니다.")
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: 300)
                                    } else {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundStyle(.yellow)
                                        Text("시간표를 불러올 수 없음")
                                            .font(.headline)
                                        Text(errorMsg)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: 300)
                                    }
                                }
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.regularMaterial)
                                }
                                .id(offset)
                                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                            } else {
                                // TODO: Replace with skeleton view
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .id(offset)
                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $model.currentWeekIndex, anchor: .center)

                Spacer()
            }
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(destination: PreferencesView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItemGroup(placement: .topBarLeading) {
                    Menu {
                        Picker(selection: $viewMode, label: Text("보기 옵션")) {
                            Text("기본").tag("작게")
                            Text("크게").tag("크게")
                        }
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if (model.currentWeekIndex != 0) {
                        Button(action: {
                            withAnimation {
                                model.currentWeekIndex = 0
                            }
                        }) {
                            Text("오늘")
                        }
                    }

                    Spacer()
                }
            }
            .onAppear {
                if model.weeks.isEmpty {
                    Task {
                        await model.loadThreeWeeks()
                    }
                }
            }
            .onChange(of: model.currentWeekIndex) { _, newValue in
                if let newValue {
                    Task {
                        await model.handleWeekChange(to: newValue)
                    }
                }
            }
            .task {
                await model.checkForUpdates() // Fetch for updated data
                model.clearOldCache()   // Remove old cache
                CacheManager.shared.reloadWidgetsIfNeeded() // Reload widgets if needed
            }
            .sheet(item: $selectedItem) { item in
                TimetableDetailsView(column: item)
                    .environmentObject(aliasStore)
            }
        }
    }
}

// MARK: - Subviews
struct TimetableGridView: View {
    let week: TimetableWeek
    var columns: [GridItem] = Array(repeating: .init(.flexible(), alignment: .top), count: 5)
    @Binding var selectedItem: TimetableColumn?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(week.days) { day in
                    VStack {
                        Text(DateFormatters.monthDay.string(from: day.date))
                            .font(.footnote)

                        ForEach(day.columns) { column in
                            TimetableItemView(
                                column: column,
                                isToday: PreferencesManager.shared.isToday(day.date),
                                dayLength: day.columns.count,
                                selectedItem: $selectedItem
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: 500)
            .padding()
        }
    }
}

struct TimetableItemView: View {
    let column: TimetableColumn
    let isToday: Bool
    let dayLength: Int
    @AppStorage("viewMode") private var viewMode: String = "작게"
    @EnvironmentObject var aliasStore: AliasStore
    @Binding var selectedItem: TimetableColumn?

    var displayName: String {
        aliasStore.aliases[column.subject]?.normal.nonEmpty ?? column.subject
    }

    var compactDisplayName: String {
        aliasStore.aliases[column.subject]?.compact.nonEmpty ?? String(column.subject.firstMeaningfulCharacter.map { String($0) } ?? "")
    }

    var body: some View {
        Button {
            selectedItem = column
        } label: {
            if isToday {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("AccentColor"))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Text(viewMode == "크게" ? compactDisplayName : displayName)
                            .font(viewMode == "크게" ? .title : .body)
                            .bold()
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                            .padding(3)
                    }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.regularMaterial)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Text(viewMode == "크게" ? compactDisplayName : displayName)
                            .font(viewMode == "크게" ? .title.bold() : .body)
                            .foregroundStyle(Color(UIColor.label))
                            .minimumScaleFactor(0.5)
                            .padding(3)
                    }
            }
        }
    }
}

#Preview {
    TimetableView()
}
