//
//  Recording.swift
//  rrrr
//
//  録音データのモデル
//

import Foundation

struct Recording: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let createdAt: Date
    let duration: TimeInterval

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.url == rhs.url
    }
}
