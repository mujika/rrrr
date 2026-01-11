//
//  ContentView.swift
//  rrrr
//
//  録音アプリのメインビュー
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 録音コントロール
                RecordingControlView(audioRecorder: audioRecorder)

                Divider()

                // 録音リスト
                if audioRecorder.recordings.isEmpty {
                    EmptyStateView()
                } else {
                    RecordingListView(audioRecorder: audioRecorder)
                }
            }
            .navigationTitle("ボイスメモ")
            .alert("マイクへのアクセス", isPresented: $showingPermissionAlert) {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("録音するにはマイクへのアクセスを許可してください。")
            }
            .alert("エラー", isPresented: .init(
                get: { audioRecorder.errorMessage != nil },
                set: { if !$0 { audioRecorder.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = audioRecorder.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            checkMicrophonePermission()
        }
    }

    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        case .denied:
            showingPermissionAlert = true
        case .granted:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Recording Control View
struct RecordingControlView: View {
    @ObservedObject var audioRecorder: AudioRecorder

    var body: some View {
        VStack(spacing: 20) {
            // 録音時間表示
            Text(formatTime(audioRecorder.recordingTime))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(audioRecorder.isRecording ? .red : .primary)

            // 録音ボタン
            Button(action: {
                if audioRecorder.isRecording {
                    audioRecorder.stopRecording()
                } else {
                    audioRecorder.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(audioRecorder.isRecording ? Color.red.opacity(0.2) : Color.red.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Circle()
                        .stroke(Color.red, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    if audioRecorder.isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: audioRecorder.isRecording)

            Text(audioRecorder.isRecording ? "タップして停止" : "タップして録音")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("録音がありません")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("上のボタンをタップして録音を開始してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Recording List View
struct RecordingListView: View {
    @ObservedObject var audioRecorder: AudioRecorder

    var body: some View {
        List {
            ForEach(audioRecorder.recordings) { recording in
                RecordingRowView(
                    recording: recording,
                    isPlaying: audioRecorder.isPlayingURL(recording.url),
                    currentTime: audioRecorder.currentTime,
                    onPlayPause: {
                        if audioRecorder.isPlayingURL(recording.url) {
                            audioRecorder.stopPlayback()
                        } else {
                            audioRecorder.startPlayback(url: recording.url)
                        }
                    }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    audioRecorder.deleteRecording(at: audioRecorder.recordings[index].url)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Recording Row View
struct RecordingRowView: View {
    let recording: Recording
    let isPlaying: Bool
    let currentTime: TimeInterval
    let onPlayPause: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 再生/停止ボタン
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(isPlaying ? .red : .blue)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("・")
                        .foregroundColor(.secondary)

                    Text(isPlaying ? formatTime(currentTime) : recording.formattedDuration)
                        .font(.caption)
                        .foregroundColor(isPlaying ? .blue : .secondary)
                        .monospacedDigit()
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
