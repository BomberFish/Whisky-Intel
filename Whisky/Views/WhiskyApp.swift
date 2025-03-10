//
//  WhiskyApp.swift
//  Whisky
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import SwiftUI
import Sparkle

@main
struct WhiskyApp: App {
    @State var showSetup: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(showSetup: $showSetup)
                .environmentObject(BottleVM.shared)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        // Don't ask me how this works, it just does
        .handlesExternalEvents(matching: ["{same path of URL?}"])
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(action: {
                    appDelegate.showAboutPanel()
                }) {
                    Text("About Whisky")
                }
            }

            CommandGroup(after: .appInfo) {
                SparkleView(updater: updaterController.updater)
                Divider()
                Button("open.setup") {
                    showSetup = true
                }
                Button("install.cli") {
                    Task {
                        await WhiskyCmd.install()
                    }
                }
            }
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .newItem) {
                Button("open.bottle") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = false
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                BottleVM.shared.bottlesList.paths.append(url)
                                BottleVM.shared.loadBottles()
                            }
                        }
                    }
                }
                .keyboardShortcut("I", modifiers: [.command])
            }
            CommandGroup(after: .importExport) {
                Button("open.logs") {
                    WhiskyApp.openLogsFolder()
                }
                .keyboardShortcut("L", modifiers: [.command])
                Button("kill.bottles") {
                    WhiskyApp.killBottles()
                }
                .keyboardShortcut("K", modifiers: [.command, .shift])
                Button("wine.clearShaderCaches") {
                    WhiskyApp.killBottles() // Better not make things more complicated for ourselves
                    WhiskyApp.wipeShaderCaches()
                }
            }
        }
    }

    static func killBottles() {
        for bottle in BottleVM.shared.bottles {
            do {
                try Wine.killBottle(bottle: bottle)
            } catch {
                print("Failed to kill bottle: \(error)")
            }
        }
    }

    static func openLogsFolder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: Log.logsFolder.path)
    }

    static func wipeShaderCaches() {
        let getconf = Process()
        getconf.executableURL = URL(fileURLWithPath: "/usr/bin/getconf")
        getconf.arguments = ["DARWIN_USER_CACHE_DIR"]
        let pipe = Pipe()
        getconf.standardOutput = pipe
        do {
            try getconf.run()
        } catch {
            return
        }
        getconf.waitUntilExit()

        let getconfOutput = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let getconfOutputString = String(data: getconfOutput, encoding: .utf8) else {
            return
        }

        let d3dmPath = URL(fileURLWithPath: getconfOutputString.trimmingCharacters(in: .whitespacesAndNewlines))
            .appending(path: "d3dm").path
        do {
            try FileManager.default.removeItem(atPath: d3dmPath)
        } catch {
            return
        }
    }
}
