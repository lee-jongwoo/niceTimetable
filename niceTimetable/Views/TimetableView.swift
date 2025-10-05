//
//  ContentView.swift
//  niceTimetable
//
//  Created by 이종우 on 9/30/25.
//

import SwiftUI

struct TimetableView: View {
    @StateObject private var viewModel = TimetableViewModel()
    
    var viewModes = ["작게", "크게"]
    @AppStorage("viewMode") private var viewMode: String = "작게"
    
    var body: some View {
        NavigationStack {
            TabView(selection: $viewModel.currentWeekIndex) {
                ForEach(-5...3, id: \.self) { offset in
                    TimetableGridView(week: viewModel.weeks[offset] ?? TimetableWeek(days: [], weekInterval: offset))
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .navigationTitle("시간표")
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
                    if (viewModel.currentWeekIndex < -1) || (viewModel.currentWeekIndex > 1) {
                        Button(action: {
                            withAnimation {
                                viewModel.currentWeekIndex = 0
                            }
                        }) {
                            Text("오늘")
                        }
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                viewModel.loadThreeWeeks()
            }
            .onChange(of: viewModel.currentWeekIndex) {
                viewModel.handleWeekChange(to: viewModel.currentWeekIndex)
            }
            .task {
                viewModel.checkForUpdates() // Fetch for updated data
                viewModel.clearOldCache()   // Remove old cache
            }
            .refreshable {
                viewModel.checkForUpdates(weekInterval: viewModel.currentWeekIndex)
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .padding()
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Subviews
struct TimetableGridView: View {
    let week: TimetableWeek
    var columns: [GridItem] = Array(repeating: .init(.flexible(), alignment: .top), count: 5)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(week.days) { day in
                    VStack {
                        Text(day.date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits)))
                            .font(.footnote)
                        
                        ForEach(day.columns) { column in
                            TimetableItemView(column: column, isToday: Calendar.current.isDateInToday(day.date), dayLength: day.columns.count)
                        }
                    }
                }
            }
            .frame(maxWidth: 500)
            .padding()
        }
        .tag(week.weekInterval)
    }
}

struct TimetableItemView: View {
    let column: TimetableColumn
    let isToday: Bool
    let dayLength: Int
    @AppStorage("viewMode") private var viewMode: String = "작게"
    @EnvironmentObject var aliasStore: AliasStore
    
    var displayName: String {
        aliasStore.aliases[column.subject]?.normal.nonEmpty ?? column.subject
    }
    
    var compactDisplayName: String {
        aliasStore.aliases[column.subject]?.compact.nonEmpty ?? String(column.subject.firstMeaningfulCharacter.map { String($0) } ?? "")
    }
    
    var body: some View {
        NavigationLink(destination: TimetableDetailsView(column: column)) {
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
