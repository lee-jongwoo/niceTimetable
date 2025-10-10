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
            SetSchoolView(isWelcomeScreen: true)
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
            .controlSize(.extraLarge)
            .modify {
                if #available(iOS 26, *) {
                    $0.buttonStyle(.glassProminent)
                } else {
                    $0.buttonStyle(.borderedProminent)
                }
            }
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
