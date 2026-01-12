//
//  SleepSession.swift
//  rrrr
//
//  睡眠セッションのデータモデル
//

import Foundation

struct SleepSession: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let quality: SleepQuality
    let memo: String

    init(id: UUID = UUID(), startTime: Date, endTime: Date, quality: SleepQuality = .good, memo: String = "") {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
        self.memo = memo
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)時間\(minutes)分"
    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: startTime)
    }

    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: endTime)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: startTime)
    }

    var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: startTime)
    }

    static func == (lhs: SleepSession, rhs: SleepSession) -> Bool {
        lhs.id == rhs.id
    }
}

enum SleepQuality: Int, Codable, CaseIterable {
    case poor = 1
    case fair = 2
    case good = 3
    case excellent = 4

    var label: String {
        switch self {
        case .poor: return "悪い"
        case .fair: return "普通"
        case .good: return "良い"
        case .excellent: return "最高"
        }
    }

    var emoji: String {
        switch self {
        case .poor: return "😴"
        case .fair: return "😐"
        case .good: return "😊"
        case .excellent: return "🌟"
        }
    }

    var color: String {
        switch self {
        case .poor: return "qualityPoor"
        case .fair: return "qualityFair"
        case .good: return "qualityGood"
        case .excellent: return "qualityExcellent"
        }
    }
}
