//
//  SleepTracker.swift
//  rrrr
//
//  睡眠追跡を管理するクラス
//

import Foundation
import Combine

class SleepTracker: ObservableObject {

    // MARK: - Published Properties
    @Published var isSleeping = false
    @Published var sessions: [SleepSession] = []
    @Published var currentSleepTime: TimeInterval = 0
    @Published var sleepStartTime: Date?
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var timer: Timer?
    private let storageKey = "sleepSessions"

    // MARK: - Computed Properties
    var todaySleep: TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions
            .filter { calendar.startOfDay(for: $0.startTime) == today }
            .reduce(0) { $0 + $1.duration }
    }

    var weeklyAverage: TimeInterval {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSessions = sessions.filter { $0.startTime >= weekAgo }
        guard !recentSessions.isEmpty else { return 0 }
        let totalDuration = recentSessions.reduce(0) { $0 + $1.duration }
        return totalDuration / 7
    }

    var thisWeekSessions: [SleepSession] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime >= weekAgo }
    }

    var averageQuality: Double {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.quality.rawValue }
        return Double(total) / Double(sessions.count)
    }

    // MARK: - Initialization
    init() {
        loadSessions()
    }

    // MARK: - Sleep Control Methods
    func startSleep() {
        sleepStartTime = Date()
        isSleeping = true
        currentSleepTime = 0
        startTimer()
    }

    func endSleep(quality: SleepQuality = .good, memo: String = "") {
        guard let startTime = sleepStartTime else { return }

        let session = SleepSession(
            startTime: startTime,
            endTime: Date(),
            quality: quality,
            memo: memo
        )

        sessions.insert(session, at: 0)
        saveSessions()

        isSleeping = false
        sleepStartTime = nil
        currentSleepTime = 0
        stopTimer()
    }

    func cancelSleep() {
        isSleeping = false
        sleepStartTime = nil
        currentSleepTime = 0
        stopTimer()
    }

    // MARK: - Session Management
    func deleteSession(_ session: SleepSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func updateSession(_ session: SleepSession, quality: SleepQuality, memo: String) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            let updated = SleepSession(
                id: session.id,
                startTime: session.startTime,
                endTime: session.endTime,
                quality: quality,
                memo: memo
            )
            sessions[index] = updated
            saveSessions()
        }
    }

    // MARK: - Timer Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.sleepStartTime else { return }
            self.currentSleepTime = Date().timeIntervalSince(startTime)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Persistence
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            sessions = try JSONDecoder().decode([SleepSession].self, from: data)
        } catch {
            errorMessage = "読み込みに失敗しました: \(error.localizedDescription)"
            sessions = []
        }
    }

    // MARK: - Statistics
    func sessionsForDate(_ date: Date) -> [SleepSession] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return sessions.filter { calendar.startOfDay(for: $0.startTime) == targetDay }
    }

    func totalSleepForDate(_ date: Date) -> TimeInterval {
        sessionsForDate(date).reduce(0) { $0 + $1.duration }
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)時間\(minutes)分"
    }

    func formatShortDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
