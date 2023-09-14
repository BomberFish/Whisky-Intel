//
//  AboutView.swift
//  Whisky
//
//  Created by Hariz Shirazi on 2023-09-14.
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
