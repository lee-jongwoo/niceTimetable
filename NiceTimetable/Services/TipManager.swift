//
//  TipManager.swift
//  NiceTimetable
//
//  Created by 이종우 on 10/17/25.
//

import Foundation
import TipKit

struct AliasTip: Tip {
    var title: Text {
        Text("별칭 지정하기")
    }

    var message: Text? {
        Text("과목 칸을 탭하여 별칭을 지정해보세요. 선택 과목을 표시하거나 시간표를 더 알아보기 쉽게 바꿀 수 있습니다.")
    }

    static let didSetAlias: Event = Event(id: "didSetAlias")

    var rules: [Rule] {
        #Rule(NiceTimetableApp.timetableAppDidOpen) { $0.donations.donatedWithin(.week).count >= 3 }
        #Rule(Self.didSetAlias) { $0.donations.count == 0 }
    }
}

struct SwipeTip: Tip {
    var title: Text {
        Text("스와이프해서 넘기기")
    }

    var message: Text? {
        Text("쓸어넘겨서 다른 기간의 시간표를 볼 수 있습니다.")
    }

    var image: Image? {
        Image(systemName: "hand.draw")
    }

    static let didSwipe: Event = Event(id: "didSwipe")

    var rules: [Rule] {
        #Rule(NiceTimetableApp.timetableAppDidOpen) { $0.donations.donatedWithin(.week).count >= 2 }
        #Rule(Self.didSwipe) { $0.donations.count == 0 }
    }
}
