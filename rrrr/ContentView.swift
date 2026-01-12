//
//  ContentView.swift
//  rrrr
//
//  睡眠アプリのメインビュー
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sleepTracker = SleepTracker()
    @State private var selectedTab = 0
    @State private var showingEndSleepSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // メイン睡眠画面
            SleepMainView(sleepTracker: sleepTracker, showingEndSleepSheet: $showingEndSleepSheet)
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("睡眠")
                }
                .tag(0)

            // 履歴画面
            SleepHistoryView(sleepTracker: sleepTracker)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("履歴")
                }
                .tag(1)

            // 統計画面
            SleepStatsView(sleepTracker: sleepTracker)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
                .tag(2)
        }
        .preferredColorScheme(.dark)
        .tint(.indigo)
        .sheet(isPresented: $showingEndSleepSheet) {
            EndSleepSheet(sleepTracker: sleepTracker, isPresented: $showingEndSleepSheet)
        }
    }
}

// MARK: - Sleep Main View
struct SleepMainView: View {
    @ObservedObject var sleepTracker: SleepTracker
    @Binding var showingEndSleepSheet: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: sleepTracker.isSleeping
                        ? [Color(hex: "1a1a2e"), Color(hex: "16213e")]
                        : [Color(hex: "0f0f1a"), Color(hex: "1a1a2e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 星のエフェクト
                StarsView()

                VStack(spacing: 30) {
                    Spacer()

                    // 月のアイコン
                    MoonView(isSleeping: sleepTracker.isSleeping)

                    // 時間表示
                    if sleepTracker.isSleeping {
                        VStack(spacing: 8) {
                            Text("おやすみなさい")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))

                            Text(formatSleepTime(sleepTracker.currentSleepTime))
                                .font(.system(size: 56, weight: .thin, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            if let startTime = sleepTracker.sleepStartTime {
                                Text("\(formatTime(startTime)) から睡眠中")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text(greeting)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))

                            if sleepTracker.todaySleep > 0 {
                                Text("今日の睡眠: \(sleepTracker.formatDuration(sleepTracker.todaySleep))")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }

                    Spacer()

                    // メインボタン
                    SleepButton(
                        isSleeping: sleepTracker.isSleeping,
                        action: {
                            if sleepTracker.isSleeping {
                                showingEndSleepSheet = true
                            } else {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    sleepTracker.startSleep()
                                }
                            }
                        }
                    )

                    // サブボタン（睡眠中のみ）
                    if sleepTracker.isSleeping {
                        Button(action: {
                            withAnimation {
                                sleepTracker.cancelSleep()
                            }
                        }) {
                            Text("キャンセル")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    Spacer()
                        .frame(height: 60)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "おはようございます"
        case 12..<17: return "こんにちは"
        case 17..<21: return "こんばんは"
        default: return "そろそろ寝る時間です"
        }
    }

    private func formatSleepTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Moon View
struct MoonView: View {
    let isSleeping: Bool
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // グロー効果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.indigo.opacity(isSleeping ? 0.4 : 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)

            // 月
            Image(systemName: isSleeping ? "moon.zzz.fill" : "moon.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "f5f3c1"), Color(hex: "e8d5a3")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "f5f3c1").opacity(0.5), radius: 20)
        }
        .scaleEffect(isSleeping ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isSleeping)
    }
}

// MARK: - Stars View
struct StarsView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<30, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height * 0.6)
                    )
            }
        }
    }
}

// MARK: - Sleep Button
struct SleepButton: View {
    let isSleeping: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // 外側のリング
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isSleeping
                                ? [Color.orange, Color.yellow]
                                : [Color.indigo, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 140, height: 140)

                // 内側の円
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSleeping
                                ? [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)]
                                : [Color.indigo.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)

                VStack(spacing: 4) {
                    Image(systemName: isSleeping ? "sun.max.fill" : "bed.double.fill")
                        .font(.system(size: 32))

                    Text(isSleeping ? "起きる" : "寝る")
                        .font(.headline)
                }
                .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - End Sleep Sheet
struct EndSleepSheet: View {
    @ObservedObject var sleepTracker: SleepTracker
    @Binding var isPresented: Bool
    @State private var selectedQuality: SleepQuality = .good
    @State private var memo: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 睡眠時間サマリー
                        VStack(spacing: 8) {
                            Text("おはようございます")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))

                            Text(sleepTracker.formatDuration(sleepTracker.currentSleepTime))
                                .font(.system(size: 48, weight: .light, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        // 睡眠の質
                        VStack(alignment: .leading, spacing: 12) {
                            Text("睡眠の質はどうでしたか？")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                ForEach(SleepQuality.allCases, id: \.rawValue) { quality in
                                    QualityButton(
                                        quality: quality,
                                        isSelected: selectedQuality == quality,
                                        action: { selectedQuality = quality }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)

                        // メモ
                        VStack(alignment: .leading, spacing: 12) {
                            Text("メモ（任意）")
                                .font(.headline)
                                .foregroundColor(.white)

                            TextField("夢の内容など...", text: $memo, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .lineLimit(3...6)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)

                        // 保存ボタン
                        Button(action: {
                            sleepTracker.endSleep(quality: selectedQuality, memo: memo)
                            isPresented = false
                        }) {
                            Text("記録を保存")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.indigo, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("起床")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .foregroundColor(.indigo)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Quality Button
struct QualityButton: View {
    let quality: SleepQuality
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(quality.emoji)
                    .font(.title)
                Text(quality.label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.indigo.opacity(0.5) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.indigo : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sleep History View
struct SleepHistoryView: View {
    @ObservedObject var sleepTracker: SleepTracker

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                if sleepTracker.sessions.isEmpty {
                    EmptySleepView()
                } else {
                    List {
                        ForEach(sleepTracker.sessions) { session in
                            SleepSessionRow(session: session)
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                sleepTracker.deleteSession(sleepTracker.sessions[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("睡眠履歴")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Sleep Session Row
struct SleepSessionRow: View {
    let session: SleepSession

    var body: some View {
        HStack(spacing: 16) {
            // 質アイコン
            Text(session.quality.emoji)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(Color.indigo.opacity(0.2))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.formattedDate)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text("\(session.formattedStartTime) → \(session.formattedEndTime)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                if !session.memo.isEmpty {
                    Text(session.memo)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()

            // 睡眠時間
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.indigo)

                Text(session.quality.label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Empty Sleep View
struct EmptySleepView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.indigo.opacity(0.5))

            Text("睡眠記録がありません")
                .font(.title2)
                .foregroundColor(.white.opacity(0.6))

            Text("「寝る」ボタンを押して\n睡眠の記録を開始しましょう")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Sleep Stats View
struct SleepStatsView: View {
    @ObservedObject var sleepTracker: SleepTracker

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 週間サマリー
                        WeeklySummaryCard(sleepTracker: sleepTracker)

                        // 週間グラフ
                        WeeklyChartCard(sleepTracker: sleepTracker)

                        // 統計カード
                        StatsGridView(sleepTracker: sleepTracker)
                    }
                    .padding()
                }
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Weekly Summary Card
struct WeeklySummaryCard: View {
    @ObservedObject var sleepTracker: SleepTracker

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("週間平均")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    Text(sleepTracker.formatDuration(sleepTracker.weeklyAverage))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title)
                    .foregroundColor(.indigo)
            }

            // 目標達成度（仮に7時間を目標とする）
            let targetHours: Double = 7
            let achievementRate = min(sleepTracker.weeklyAverage / (targetHours * 3600), 1.0)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("目標達成度")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(Int(achievementRate * 100))%")
                        .font(.caption)
                        .foregroundColor(.indigo)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * achievementRate, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Weekly Chart Card
struct WeeklyChartCard: View {
    @ObservedObject var sleepTracker: SleepTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("過去7日間")
                .font(.headline)
                .foregroundColor(.white)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -6 + dayOffset, to: Date()) ?? Date()
                    let sleep = sleepTracker.totalSleepForDate(date)
                    let maxHours: Double = 10
                    let heightRatio = min(sleep / (maxHours * 3600), 1.0)

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.indigo, .purple.opacity(0.7)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(4, 120 * heightRatio))

                        Text(weekdayLabel(for: date))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return String(formatter.string(from: date).prefix(1))
    }
}

// MARK: - Stats Grid View
struct StatsGridView: View {
    @ObservedObject var sleepTracker: SleepTracker

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                icon: "bed.double.fill",
                title: "合計記録",
                value: "\(sleepTracker.sessions.count)回",
                color: .indigo
            )

            StatCard(
                icon: "star.fill",
                title: "平均品質",
                value: String(format: "%.1f", sleepTracker.averageQuality),
                color: .yellow
            )

            StatCard(
                icon: "clock.fill",
                title: "今日",
                value: sleepTracker.formatShortDuration(sleepTracker.todaySleep),
                color: .green
            )

            StatCard(
                icon: "calendar",
                title: "今週",
                value: "\(sleepTracker.thisWeekSessions.count)回",
                color: .orange
            )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
