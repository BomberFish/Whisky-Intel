//
//  AppDelegate.swift
//  Whisky
//
//  Created by Viacheslav Shkliarov on 08.06.2023.
//

import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("hasShownMoveToApplicationsAlert") private var hasShownMoveToApplicationsAlert = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !hasShownMoveToApplicationsAlert && !AppDelegate.insideAppsFolder {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                NSApp.activate(ignoringOtherApps: true)
                self.showAlertOnFirstLaunch()
                self.hasShownMoveToApplicationsAlert = true
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        WhiskyApp.killBottles()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private static var appUrl: URL? {
        Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent()
    }

    private static var expectedUrl = URL(fileURLWithPath: "/Applications/Whisky.app")

    private static var insideAppsFolder: Bool {
        if let url = appUrl {
            return url.path.contains("Xcode") || url.path.contains(expectedUrl.path)
        }
        return false
    }

    private func showAlertOnFirstLaunch() {
        let alert = NSAlert()
        alert.messageText = String(localized: "showAlertOnFirstLaunch.messageText")
        alert.informativeText = String(localized: "showAlertOnFirstLaunch.informativeText")
        alert.addButton(withTitle: String(localized: "showAlertOnFirstLaunch.button.moveToApplications"))
        alert.addButton(withTitle: String(localized: "showAlertOnFirstLaunch.button.dontMove"))

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let appURL = Bundle.main.bundleURL

            do {
                _ = try FileManager.default.replaceItemAt(AppDelegate.expectedUrl, withItemAt: appURL)
                NSWorkspace.shared.open(AppDelegate.expectedUrl)
            } catch {
                print("Failed to move the app: \(error)")
            }
        }
    }

    private var aboutBoxWindowController: NSWindowController?

        func showAboutPanel() {
            if aboutBoxWindowController == nil {
                let styleMask: NSWindow.StyleMask = [.closable, .titled]
                let window = NSWindow()
                window.styleMask = styleMask
                window.title = "About"
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.contentView = NSHostingView(rootView: AboutView())
                aboutBoxWindowController = NSWindowController(window: window)
            }

            aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
        }
}
