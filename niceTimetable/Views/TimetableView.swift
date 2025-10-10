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
            TabView(selection: $model.currentWeekIndex) {
                ForEach(-5...3, id: \.self) { offset in
                    if let week = model.weeks[offset] {
                        TimetableGridView(week: week, selectedItem: $selectedItem)
                            .environmentObject(aliasStore)
                    }
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
                    if (model.currentWeekIndex < -1) || (model.currentWeekIndex > 1) {
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
                Task {
                    await model.loadThreeWeeks()
                }
            }
            .onChange(of: model.currentWeekIndex) {
                Task {
                    await model.handleWeekChange(to: model.currentWeekIndex)
                }
            }
            .task {
                await model.checkForUpdates() // Fetch for updated data
                model.clearOldCache()   // Remove old cache
            }
            .refreshable {
                await model.checkForUpdates(weekInterval: model.currentWeekIndex)
            }
            .sheet(item: $selectedItem) { item in
                TimetableDetailsView(column: item)
                    .environmentObject(aliasStore)
            }
            .overlay {
                if let error = model.errorMessage {
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
    @Binding var selectedItem: TimetableColumn?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(week.days) { day in
                    VStack {
                        Text(day.date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits)))
                            .font(.footnote)
                        
                        ForEach(day.columns) { column in
                            TimetableItemView(column: column, isToday: Calendar.current.isDateInToday(day.date), dayLength: day.columns.count, selectedItem: $selectedItem)
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
