//
//  NudgeTestToolApp.swift
//  NudgeTestTool
//
//  Created by George Babichev on 12/17/25.
//

import SwiftUI

@main
struct NudgeTestToolApp: App {
    @StateObject private var model = NudgeViewModel()
    @State private var isAboutPresented: Bool = false
    @State private var isShowingFileImporter: Bool = false
    @State private var shouldLoadSelectionInBuilder: Bool = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("Nudgr", id: "main") {
            ContentView(
                model: model,
                isShowingFileImporter: $isShowingFileImporter,
                shouldLoadSelectionInBuilder: $shouldLoadSelectionInBuilder
            )
                .sheet(isPresented: $isAboutPresented) {
                    AboutView()
                }
        }
        .windowStyle(.hiddenTitleBar)
        Window("JSON Builder", id: "json-builder") {
            JSONBuilder(
                model: model,
                loadFromSelection: $shouldLoadSelectionInBuilder
            )
            .id((shouldLoadSelectionInBuilder ? "edit" : "new") + "|" + model.selectedJSONPath)
        }
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
                    shouldLoadSelectionInBuilder = false
                    openWindow(id: "json-builder")
                } label: {
                    Label("New JSON File", systemImage: "doc.badge.plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                Button {
                    shouldLoadSelectionInBuilder = true
                    model.refreshSelectedJSON()
                    openWindow(id: "json-builder")
                } label: {
                    Label("Edit JSON", systemImage: "pencil")
                }
                .disabled(model.selectedJSONPath.isEmpty)
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
