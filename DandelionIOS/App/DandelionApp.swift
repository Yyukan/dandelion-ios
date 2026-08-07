//
//  DandelionApp.swift
//  Dandelion
//
//  Standard iOS app entry point; ContentView is a normal root view hosted in
//  a WindowGroup. onOpenURL handles the Lock Screen widgets' tap target
//  (dandelion://open) - a no-op landing, since the app already opens
//  straight to the dashboard.
//

import SwiftUI

@main
struct DandelionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { _ in }
        }
    }
}
