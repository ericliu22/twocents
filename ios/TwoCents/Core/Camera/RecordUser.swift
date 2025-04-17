//
//  RecordUser.swift
//  TwoCents
//
//  Created by Eric Liu on 4/17/25.
//

import SwiftUI
import AVFoundation
import AVKit
import Photos

/// MARK: - High‑level entry view
/// Embeds a live front‑camera preview, a record/stop toggle, and (after recording) a review sheet
/// A view that *silently* records the user’s face with the front‑facing camera as soon as it appears.
/// After recording for the configured duration (default 5 s) a review sheet lets the user delete or upload.
struct AutoFaceRecorderView: View {
    @StateObject private var viewModel = AutoRecorderViewModel(recordSeconds: 5)

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session)
                .ignoresSafeArea()

            // Simple HUD letting the user know recording is in progress.
            if viewModel.isRecording {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "video.fill")
                            .padding(.leading, 6)
                        ProgressView(value: viewModel.elapsed, total: viewModel.recordSeconds)
                            .progressViewStyle(.linear)
                            .frame(height: 4)
                            .padding(.trailing, 6)
                    }
                    .padding(12)
                    .background(Material.thin)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.bottom, 32)
                }
                .transition(.opacity)
            }
        }
        .sheet(item: $viewModel.finishedRecording) { output in
            VideoReviewView(recording: output,
                             onDiscard: viewModel.discardRecording,
                             onUpload: viewModel.uploadRecording)
        }
        .task {
            await viewModel.bootstrap()
        }
    }
}

// MARK: - ViewModel
@MainActor
final class AutoRecorderViewModel: NSObject, ObservableObject {
    // Public observable state
    @Published var isRecording = false
    @Published var elapsed: Double = 0
    @Published var finishedRecording: VideoOutput? = nil

    // Configurable duration
    let recordSeconds: Double

    // Capture session & output
    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()

    private var outputURL: URL?
    private var timer: Timer?

    init(recordSeconds: Double = 5) {
        self.recordSeconds = recordSeconds
    }

    /// Call once from the view .task
    func bootstrap() async {
        await configureSession()
        startAutoRecording()
    }

    private func configureSession() async {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Front camera
        guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let camInput = try? AVCaptureDeviceInput(device: cam),
              session.canAddInput(camInput) else {
            print("⚠️ Cannot access front camera")
            return
        }
        session.addInput(camInput)

        // Microphone (optional but recommended)
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }

        // Output
        guard session.canAddOutput(movieOutput) else { return }
        session.addOutput(movieOutput)
        session.commitConfiguration()
        session.startRunning()
    }

    // MARK: Recording cycle
    private func startAutoRecording() {
        guard !isRecording else { return }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        try? FileManager.default.removeItem(at: temp)
        movieOutput.startRecording(to: temp, recordingDelegate: self)
        outputURL = temp
        isRecording = true

        // progress timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.elapsed += 0.1
            if self.elapsed >= self.recordSeconds {
                self.stopRecording()
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        timer?.invalidate()
        timer = nil
    }

    // MARK: User actions in review sheet
    func discardRecording(_ output: VideoOutput) {
        try? FileManager.default.removeItem(at: output.url)
        finishedRecording = nil
    }

    func uploadRecording(_ output: VideoOutput) {}
}

extension AutoRecorderViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.elapsed = 0
            if error == nil {
                self.finishedRecording = VideoOutput(url: outputFileURL)
            } else {
                print("Recording error: \(String(describing: error))")
            }
        }
    }
}


// MARK: - ViewModel
@MainActor @Observable
final class RecorderViewModel: NSObject {
    // Public state
    var isRecording = false
    var finishedRecording: VideoOutput? = nil

    // Capture session objects
    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()

    // Temporary recording URL
    private var outputURL: URL?

    /// One‑time configuration of the capture session.
    func configureSession() async {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Front camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            print("⚠️ Unable to access front camera")
            return
        }
        session.addInput(videoInput)

        // Microphone input (optional but recommended)
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }

        // Movie file output
        guard session.canAddOutput(movieOutput) else { return }
        session.addOutput(movieOutput)
        session.commitConfiguration()
        session.startRunning()
    }

    /// Start / stop recording depending on current state
    func toggleRecording() {
        if isRecording {
            movieOutput.stopRecording()
            isRecording = false
        } else {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".mov"
            let url = tempDir.appendingPathComponent(fileName)
            // Remove old temp files if any
            try? FileManager.default.removeItem(at: url)
            movieOutput.startRecording(to: url, recordingDelegate: self)
            outputURL = url
            isRecording = true
        }
    }

    /// Delete the recording and reset state
    func discardRecording(_ output: VideoOutput) {
        try? FileManager.default.removeItem(at: output.url)
        finishedRecording = nil
    }

    /// Upload the recording. Replace the placeholder with your own logic.
    func uploadRecording(_ output: VideoOutput) {}
}

extension RecorderViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
            return
        }
        DispatchQueue.main.async {
            self.finishedRecording = VideoOutput(url: outputFileURL)
        }
    }
}

// MARK: - Model for completed recordings
struct VideoOutput: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Camera preview layer wrapper
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        var session: AVCaptureSession? {
            get { videoPreviewLayer.session }
            set { videoPreviewLayer.session = newValue }
        }
    }
}

// MARK: - Review sheet
struct VideoReviewView: View {
    let recording: VideoOutput
    let onDiscard: (VideoOutput) -> Void
    let onUpload: (VideoOutput) -> Void

    var body: some View {
        VStack {
            VideoPlayerContainer(url: recording.url)
                .frame(maxHeight: 400)
                .cornerRadius(12)
                .padding()
            HStack(spacing: 24) {
                Button(role: .destructive) { onDiscard(recording) } label: {
                    Label("Discard", systemImage: "trash")
                }
                Button { onUpload(recording) } label: {
                    Label("Upload", systemImage: "icloud.and.arrow.up")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .presentationDetents([.medium])
    }
}

private struct VideoPlayerContainer: View {
    let url: URL
    @State private var player: AVPlayer? = nil

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
                player?.play()
            }
            .onDisappear { player?.pause() }
    }
}
