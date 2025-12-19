//
//  NudgeTestToolApp.swift
//  NudgeTestTool
//
//  Created by George Babichev on 12/17/25.
//

import SwiftUI

@main
struct NudgeTestToolApp: App {
    @State private var isAboutPresented: Bool = false
    @State private var isShowingFileImporter: Bool = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("Nudgr", id: "main") {
            ContentView(isShowingFileImporter: $isShowingFileImporter)
                .sheet(isPresented: $isAboutPresented) {
                    AboutView()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button {
                    isAboutPresented = true
                } label: {
                    Label("About Nudgr", systemImage: "info.circle")
                }
            }
            CommandGroup(replacing: .newItem) {
                Button {
                    openWindow(id: "main")
                } label: {
                    Label("New Window", systemImage: "square.on.square")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .newItem) {
                Button {
                    isShowingFileImporter = true
                } label: {
                    Label("Open JSON…", systemImage: "doc")
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
