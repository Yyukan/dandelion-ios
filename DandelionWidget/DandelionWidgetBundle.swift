//
//  DandelionWidgetBundle.swift
//  DandelionWidget
//
//  Widget extension entry point - combines the four independently-addable
//  Lock Screen complications (Balance, Hour, Weekly, Monthly limit) and
//  the home-screen Dashboard widget into one bundle.
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
        DashboardWidget()
    }
}
