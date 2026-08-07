//
//  DandelionWidgetBundle.swift
//  DandelionWidget
//
//  Widget extension entry point - combines the 4 independently-addable
//  Lock Screen widgets (Balance, Hour/Weekly/Monthly limit) into one bundle.
//

import WidgetKit
import SwiftUI

@main
struct DandelionWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        HourLimitWidget()
        WeeklyLimitWidget()
        MonthlyLimitWidget()
    }
}
