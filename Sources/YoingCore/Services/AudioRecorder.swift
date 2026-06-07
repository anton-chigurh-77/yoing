import AVFoundation
import Foundation

public enum AudioRecorderError: LocalizedError {
    case alreadyRecording
    case notRecording
    case failedToStart
    case emptyRecording
    case missingAudioFile

    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Yoing is already recording."
        case .notRecording:
            return "Yoing is not recording."
        case .failedToStart:
            return "The microphone recording could not start."
        case .emptyRecording:
            return "The recording was too short to transcribe."
        case .missingAudioFile:
            return "The temporary recording could not be read."
        }
    }
}

public final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    public init() {}

    public var isRecording: Bool {
        recorder?.isRecording == true
    }

    public func start() throws {
        guard recorder == nil else {
            throw AudioRecorderError.alreadyRecording
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yoing-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw AudioRecorderError.failedToStart
        }

        self.recorder = recorder
        recordingURL = url
    }

    public func stop() throws -> RecordedAudio {
        guard let recorder, let recordingURL else {
            throw AudioRecorderError.notRecording
        }

        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        self.recordingURL = nil

        defer {
            try? FileManager.default.removeItem(at: recordingURL)
        }

        guard duration >= 0.2 else {
            throw AudioRecorderError.emptyRecording
        }

        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            throw AudioRecorderError.missingAudioFile
        }

        let data = try Data(contentsOf: recordingURL)
        guard !data.isEmpty else {
            throw AudioRecorderError.emptyRecording
        }

        return RecordedAudio(
            data: data,
            filename: "yoing-dictation.m4a",
            mimeType: "audio/m4a",
            duration: duration
        )
    }

    public func discard() {
        recorder?.stop()
        recorder = nil

        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }

        recordingURL = nil
    }
}
