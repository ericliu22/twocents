//
//  PhotoVideoUpload.swift
//  TwoCents
//
//  Created by Joshua Shen on 2/28/25.
//
import AVFoundation
import UIKit

class CameraManager: NSObject, ObservableObject {
    enum CaptureMode {
        case photo
        case video
    }
    
    @Published var isRecording = false
    @Published var captureMode: CaptureMode = .photo
    
    private let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureMovieFileOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var activeInput: AVCaptureDeviceInput?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        // Photo resolution preset (adjust as needed)
        session.sessionPreset = .high
        
        // Setup default camera device
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            return
        }
        
        session.addInput(input)
        activeInput = input
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        // Add video output
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func switchCamera() {
        guard let currentInput = activeInput else { return }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        let newPosition: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(newInput)
        else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        session.addInput(newInput)
        activeInput = newInput
        session.commitConfiguration()
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startVideoRecording() {
        guard !videoOutput.isRecording else { return }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
    }
    
    func stopVideoRecording() {
        guard videoOutput.isRecording else { return }
        videoOutput.stopRecording()
        isRecording = false
    }
    
    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        previewLayer?.session = session
        previewLayer?.videoGravity = .resizeAspectFill
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        // Handle the image data (e.g., save, pass to SwiftUI, etc.)
        // For demonstration, you might just store it in a published property
        // or pass a completion handler.
        print("Photo captured, size: \(data.count) bytes")
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didStartRecordingTo fileURL: URL,
                    from connections: [AVCaptureConnection]) {
        print("Started video recording: \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("Error recording video: \(error)")
        } else {
            // Handle the recorded video (e.g., save to Photo Library or your app’s documents).
            print("Video recording finished: \(outputFileURL)")
        }
    }
}


