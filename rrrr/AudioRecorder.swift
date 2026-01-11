//
//  AudioRecorder.swift
//  rrrr
//
//  録音・再生を管理するクラス
//

import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordings: [Recording] = []
    @Published var currentTime: TimeInterval = 0
    @Published var recordingTime: TimeInterval = 0
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var playingURL: URL?

    // MARK: - Initialization
    override init() {
        super.init()
        fetchRecordings()
    }

    // MARK: - Recording Methods
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            errorMessage = "オーディオセッションの設定に失敗しました: \(error.localizedDescription)"
            return
        }

        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "録音_\(dateFormatter.string(from: Date())).m4a"
        let audioFilename = documentPath.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0
            startRecordingTimer()
        } catch {
            errorMessage = "録音の開始に失敗しました: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        stopTimer()
        fetchRecordings()
    }

    // MARK: - Playback Methods
    func startPlayback(url: URL) {
        let playbackSession = AVAudioSession.sharedInstance()

        do {
            try playbackSession.setCategory(.playback, mode: .default)
            try playbackSession.setActive(true)
        } catch {
            errorMessage = "再生セッションの設定に失敗しました: \(error.localizedDescription)"
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            playingURL = url
            currentTime = 0
            startPlaybackTimer()
        } catch {
            errorMessage = "再生の開始に失敗しました: \(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playingURL = nil
        currentTime = 0
        stopTimer()
    }

    func isPlayingURL(_ url: URL) -> Bool {
        return isPlaying && playingURL == url
    }

    // MARK: - File Management
    func fetchRecordings() {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: [.creationDateKey])

            recordings = files
                .filter { $0.pathExtension == "m4a" }
                .compactMap { url -> Recording? in
                    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let creationDate = attributes[.creationDate] as? Date else {
                        return nil
                    }

                    let asset = AVURLAsset(url: url)
                    let duration = CMTimeGetSeconds(asset.duration)

                    return Recording(
                        url: url,
                        name: url.deletingPathExtension().lastPathComponent,
                        createdAt: creationDate,
                        duration: duration
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = "録音ファイルの取得に失敗しました: \(error.localizedDescription)"
            recordings = []
        }
    }

    func deleteRecording(at url: URL) {
        do {
            if isPlayingURL(url) {
                stopPlayback()
            }
            try FileManager.default.removeItem(at: url)
            fetchRecordings()
        } catch {
            errorMessage = "削除に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Timer Methods
    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingTime += 0.1
        }
    }

    private func startPlaybackTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            if let player = self?.audioPlayer {
                self?.currentTime = player.currentTime
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "録音が正常に完了しませんでした"
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.playingURL = nil
            self.currentTime = 0
            self.stopTimer()
        }
    }
}
