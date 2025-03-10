//
//  ConfigView.swift
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
import WhiskyKit

enum LoadingState {
    case loading
    case modifying
    case success
    case failed
}

struct ConfigView: View {
    @Binding var bottle: Bottle
    @State var windowsVersion: WinVersion
    @State var displayBuildVersion: String = ""
    @State var buildVersion: String = ""
    @State var retinaMode: Bool = false
    @State var dpiConfig: Int = 96
    @State var winVersionLoadingState: LoadingState = .loading
    @State var buildVersionLoadingState: LoadingState = .loading
    @State var retinaModeLoadingState: LoadingState = .loading
    @State var dpiConfigLoadingState: LoadingState = .loading
    @State var dpiSheetPresented: Bool = false
    @AppStorage("wineSectionExpanded") var wineSectionExpanded: Bool = true
    @AppStorage("dxvkSectionExpanded") var dxvkSectionExpanded: Bool = true
    @AppStorage("metalSectionExpanded") var metalSectionExpanded: Bool = true

    init(bottle: Binding<Bottle>) {
        self._bottle = bottle
        self.windowsVersion = bottle.settings.windowsVersion.wrappedValue
    }

    var body: some View {
        VStack {
            Form {
                Section("config.title.wine", isExpanded: $wineSectionExpanded) {
                    SettingItemView(title: "config.winVersion", loadingState: $winVersionLoadingState) {
                        Picker("config.winVersion", selection: $windowsVersion) {
                            ForEach(WinVersion.allCases.reversed(), id: \.self) {
                                Text($0.pretty())
                            }
                        }
                    }
                    SettingItemView(title: "config.buildVersion", loadingState: $buildVersionLoadingState) {
                        TextField("config.buildVersion", text: $displayBuildVersion)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                buildVersionLoadingState = .modifying
                                Task(priority: .userInitiated) {
                                    if let version = Int(displayBuildVersion) {
                                        do {
                                            try await Wine.changeBuildVersion(bottle: bottle, version: version)
                                        } catch {
                                            print("Failed to change build version")
                                        }
                                    } else {
                                        displayBuildVersion = buildVersion
                                    }
                                    buildVersionLoadingState = .success
                                }
                            }
                    }
                    SettingItemView(title: "config.retinaMode", loadingState: $retinaModeLoadingState) {
                        Toggle("config.retinaMode", isOn: $retinaMode)
                        .onChange(of: retinaMode) {
                            Task(priority: .userInitiated) {
                                retinaModeLoadingState = .modifying
                                do {
                                    try await Wine.changeRetinaMode(bottle: bottle, retinaMode: retinaMode)
                                } catch {
                                    print("Failed to change build version")
                                }
                                retinaModeLoadingState = .success
                            }
                        }
                    }
                    Toggle(isOn: $bottle.settings.esync) {
                        Text("config.esync")
                    }
                    SettingItemView(title: "config.dpi", loadingState: $dpiConfigLoadingState) {
                        HStack {
                            Text("config.dpi")
                            Spacer()
                            Button("config.inspect") {
                                dpiSheetPresented = true
                            }
                            .sheet(isPresented: $dpiSheetPresented) {
                                DPIConfigSheetView(
                                    dpiConfig: $dpiConfig,
                                    isRetinaMode: $retinaMode,
                                    presented: $dpiSheetPresented
                                )
                            }
                        }
                    }
                }
                Section("config.title.dxvk", isExpanded: $dxvkSectionExpanded) {
                    Toggle(isOn: $bottle.settings.dxvk) {
                        Text("config.dxvk")
                    }
                    Toggle(isOn: $bottle.settings.dxvkAsync) {
                        Text("config.dxvk.async")
                    }
                    .disabled(!bottle.settings.dxvk)
                    Picker("config.dxvkHud", selection: $bottle.settings.dxvkHud) {
                        Text("config.dxvkHud.full").tag(DXVKHUD.full)
                        Text("config.dxvkHud.partial").tag(DXVKHUD.partial)
                        Text("config.dxvkHud.fps").tag(DXVKHUD.fps)
                        Text("config.dxvkHud.off").tag(DXVKHUD.off)
                    }
                    .disabled(!bottle.settings.dxvk)
                }

                Section { } footer: {
                    Label("config.dxvk.info", systemImage: "info.circle")
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                }

                Section("config.title.metal") {
                    Toggle(isOn: $bottle.settings.metalHud) {
                        Text("config.metalHud")
                    }
                    Toggle(isOn: $bottle.settings.metalTrace) {
                        Text("config.metalTrace")
                        Text("config.metalTrace.info")
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("config.controlPanel") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.control(bottle: bottle)
                        } catch {
                            print("Failed to launch control")
                        }
                    }
                }
                Button("config.regedit") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.regedit(bottle: bottle)
                        } catch {
                            print("Failed to launch regedit")
                        }
                    }
                }
                Button("config.winecfg") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.cfg(bottle: bottle)
                        } catch {
                            print("Failed to launch winecfg")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("tab.config")
        .onAppear {
            windowsVersion = bottle.settings.windowsVersion
            winVersionLoadingState = .success

            loadBuildName()

            Task(priority: .userInitiated) {
                do {
                    retinaMode = try await Wine.retinaMode(bottle: bottle)
                    retinaModeLoadingState = .success
                } catch {
                    print(error)
                    retinaModeLoadingState = .failed
                }
            }
            Task(priority: .userInitiated) {
                do {
                    dpiConfig = try await Wine.dpiResolution(bottle: bottle)
                    dpiConfigLoadingState = .success
                } catch {
                    print(error)
                    // If DPI has not yet been edited, there will be no registry entry
                    dpiConfigLoadingState = .success
                }
            }
        }
        .onChange(of: windowsVersion) { _, newValue in
            if winVersionLoadingState == .success {
                winVersionLoadingState = .loading
                buildVersionLoadingState = .loading
                Task(priority: .userInitiated) {
                    do {
                        try await Wine.changeWinVersion(bottle: bottle, win: newValue)
                        winVersionLoadingState = .success
                        bottle.settings.windowsVersion = newValue
                        loadBuildName()
                    } catch {
                        print(error)
                        winVersionLoadingState = .failed
                        windowsVersion = bottle.settings.windowsVersion
                    }
                }
            }
        }
        .onChange(of: buildVersion) {
            // Remove anything that isn't a number
            buildVersion = buildVersion.filter("0123456789".contains)
        }
        .onChange(of: dpiConfig) {
            if dpiConfigLoadingState == .success {
                Task(priority: .userInitiated) {
                    dpiConfigLoadingState = .modifying
                    do {
                        try await Wine.changeDpiResolution(bottle: bottle, dpi: dpiConfig)
                        dpiConfigLoadingState = .success
                    } catch {
                        print(error)
                        dpiConfigLoadingState = .failed
                    }
                }
            }
        }
    }

    func loadBuildName() {
        Task(priority: .userInitiated) {
            do {
                buildVersion = try await Wine.buildVersion(bottle: bottle)
                displayBuildVersion = buildVersion
                buildVersionLoadingState = .success
            } catch {
                print(error)
                buildVersionLoadingState = .failed
            }
        }
    }
}

struct DPIConfigSheetView: View {
    @Binding var dpiConfig: Int
    @Binding var isRetinaMode: Bool
    @Binding var presented: Bool
    @State var stagedChanges: Float
    @FocusState var textFocused: Bool

    init(dpiConfig: Binding<Int>, isRetinaMode: Binding<Bool>, presented: Binding<Bool>) {
        self._dpiConfig = dpiConfig
        self._isRetinaMode = isRetinaMode
        self._presented = presented
        self.stagedChanges = Float(dpiConfig.wrappedValue)
    }

    var body: some View {
        VStack {
            HStack {
                Text("configDpi.title")
                    .fontWeight(.bold)
                Spacer()
            }
            Divider()
            GroupBox(label: Label("configDpi.preview", systemImage: "text.magnifyingglass")) {
                VStack {
                    HStack {
                        Text("configDpi.previewText")
                            .padding(16)
                            .font(.system(size:
                                (10 * CGFloat(stagedChanges)) / 72 *
                                          (isRetinaMode ? 0.5 : 1)
                            ))
                        Spacer()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: 80)
            }
            HStack {
                Slider(value: $stagedChanges, in: 96...480, step: 24, onEditingChanged: { _ in
                    textFocused = false
                })
                TextField(String(), value: $stagedChanges, format: .number)
                    .frame(width: 40)
                    .focused($textFocused)
                Text("configDpi.dpi")
            }
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    presented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("button.ok") {
                    dpiConfig = Int(stagedChanges)
                    presented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 240)
    }
}

struct SettingItemView<V: View>: View {
    var title: String.LocalizationValue
    @Binding var loadingState: LoadingState
    @ViewBuilder var content: () -> V

    var body: some View {
        if loadingState == .failed {
            HStack {
                Text(String(localized: title))
                Spacer()
                Text("config.notAvailable").opacity(0.5)
            }
        } else if loadingState == .loading {
            HStack {
                Text(String(localized: title))
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }
        } else {
            HStack(spacing: 16) {
                content()
                    .disabled(loadingState == .modifying)
                if loadingState == .modifying {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                }
            }
        }
    }
}
