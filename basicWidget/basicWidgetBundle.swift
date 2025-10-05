//
//  basicWidgetBundle.swift
//  basicWidget
//
//  Created by 이종우 on 9/30/25.
//

import WidgetKit
import SwiftUI

@main
struct basicWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeeklyWidget()
        DailyWidget()
    }
}
