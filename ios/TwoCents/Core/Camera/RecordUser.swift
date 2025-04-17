import SwiftUI
import AVFoundation
import Photos
import AVKit

/// A view that silently records the user via the front‑facing camera the moment it appears.
/// On Simulator or if the camera/mic permission is denied, it falls back to a placeholder UI
/// instead of crashing.
struct AutoFaceRecorderView: View {
    @StateObject private var viewModel = AutoRecorderViewModel(recordSeconds: 5)

    var body: some View {
        ZStack {
            if viewModel.cameraUnavailable {
                Color.black.opacity(0.8)
                VStack(spacing: 16) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 44))
                    Text("Camera unavailable without permission.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .foregroundColor(.white)
            } else {
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
            }

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
    @Published var cameraUnavailable = false

    // Configurable duration
    let recordSeconds: Double

    // Capture session & output
    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()

    private var timer: Timer?

    init(recordSeconds: Double = 5) {
        self.recordSeconds = recordSeconds
    }

    // MARK: Bootstrapping
    func bootstrap() async {
        #if targetEnvironment(simulator)
        // Simulator has no camera
        cameraUnavailable = true
        return
        #else
        guard await configureSession() else {
            cameraUnavailable = true
            return
        }
        startAutoRecording()
        #endif
    }

    /// Configure the capture session. Returns `true` on success.
    private func configureSession() async -> Bool {
        // Request permission first
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else { return false }

        session.beginConfiguration()
        session.sessionPreset = .high

        // Front camera
        guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let camInput = try? AVCaptureDeviceInput(device: cam),
              session.canAddInput(camInput) else {
            session.commitConfiguration()
            return false
        }
        session.addInput(camInput)

        // Microphone (optional)
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }

        // Output
        guard session.canAddOutput(movieOutput) else { session.commitConfiguration(); return false }
        session.addOutput(movieOutput)
        session.commitConfiguration()
        session.startRunning()
        return true
    }

    // MARK: Recording cycle
    private func startAutoRecording() {
        guard !isRecording else { return }
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        try? FileManager.default.removeItem(at: fileURL)
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true

        // Timer to stop recording after `recordSeconds`
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
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

    func uploadRecording(_ output: VideoOutput) {
        Task {
            do {
                try await Uploader.shared.uploadVideo(fileURL: output.url)
                discardRecording(output)
            } catch {
                print("Upload error: \(error)")
            }
        }
    }
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

// MARK: - Re‑usable components
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView(); v.session = session; return v
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

struct VideoOutput: Identifiable { let id = UUID(); let url: URL }

struct VideoReviewView: View {
    let recording: VideoOutput
    let onDiscard: (VideoOutput) -> Void
    let onUpload: (VideoOutput) -> Void
    var body: some View {
        VStack {
            VideoPlayer(player: AVPlayer(url: recording.url))
                .frame(maxHeight: 400)
                .cornerRadius(12)
                .padding()
            HStack(spacing: 24) {
                Button(role: .destructive) { onDiscard(recording) } label: {
                    Label("Delete", systemImage: "trash")
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

actor Uploader {
    static let shared = Uploader()
    func uploadVideo(fileURL: URL) async throws {
        // Replace with real multipart upload
        try await Task.sleep(for: .seconds(1))
    }
}
