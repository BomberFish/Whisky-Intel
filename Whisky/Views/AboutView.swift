//
//  AboutView.swift
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

struct AboutView: View {
    let version: String = "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")) "
    var body: some View {
        HStack(spacing: 20) {
            Image(nsImage: (NSImage(named: "AppIcon") ?? NSImage(data: .init(count: 0)))!)
            VStack(alignment: .leading) {
                Text("Whisky")
                    .font(.system(size: 30, weight: .light))
                Text("A modern Wine wrapper for macOS.")
                    .fontWeight(.bold)
                Text(version)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 150)
    }
}

#Preview {
    AboutView()
}
