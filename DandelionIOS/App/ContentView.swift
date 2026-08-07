//
//  ContentView.swift
//  Dandelion
//
//  Root view: owns the single long-lived AppModel and hosts DashboardView.
//  Forces dark color scheme so system chrome (nav bar title, sheets, status
//  bar) matches TerminalTheme, which is intentionally not adaptive.
//

import SwiftUI

struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        DashboardView(model: model)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
