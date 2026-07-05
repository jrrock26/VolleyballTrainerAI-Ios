import SwiftUI
import AVFoundation
import Photos
import UIKit

/// Captures the app screen as a video using AVAssetWriter,
/// bypassing ReplayKit's preview controller entirely.
class ScreenCaptureManager: NSObject, ObservableObject {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval?
    private var frameCount = 0
    private let frameDuration: Double
    private let outputURL: URL
    private var isRecording = false
    
    /// Callback with the output URL when recording stops.
    var onRecordingComplete: ((URL) -> Void)?
    /// Called with an error description if recording fails.
    var onRecordingError: ((String) -> Void)?
    
    override init() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let timestamp = Int(Date().timeIntervalSince1970)
        outputURL = URL(fileURLWithPath: "\(documentsPath)/play_recording_\(timestamp).mp4")
        // ~15 fps gives smooth enough playback without huge file sizes
        frameDuration = 1.0 / 15.0
        super.init()
    }
    
    /// Start recording screen captures.
    func startRecording() {
        guard !isRecording else { return }
        
        // Remove any previous file
        try? FileManager.default.removeItem(at: outputURL)
        
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let videoWidth = screenSize.width * scale
        let videoHeight = screenSize.height * scale
        
        guard videoWidth > 0, videoHeight > 0, videoWidth.isFinite, videoHeight.isFinite else {
            onRecordingError?("Invalid frame dimension (\(videoWidth) x \(videoHeight))")
            return
        }
        
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(videoWidth),
                AVVideoHeightKey: Int(videoHeight)
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            
            let pixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: Int(videoWidth),
                kCVPixelBufferHeightKey as String: Int(videoHeight)
            ]
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput!,
                sourcePixelBufferAttributes: pixelBufferAttributes
            )
            
            guard let assetWriter = assetWriter, let videoInput = videoInput else {
                onRecordingError?("Failed to create asset writer")
                return
            }
            
            if assetWriter.canAdd(videoInput) {
                assetWriter.add(videoInput)
            } else {
                onRecordingError?("Cannot add video input to asset writer")
                return
            }
            
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            isRecording = true
            frameCount = 0
            startTime = CACurrentMediaTime()
            
            // Start the display link to capture frames
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.displayLink = CADisplayLink(target: self, selector: #selector(self.captureFrame))
                self.displayLink?.add(to: .main, forMode: .common)
            }
            
        } catch {
            onRecordingError?("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    /// Stop recording and finalize the video file.
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        
        displayLink?.invalidate()
        displayLink = nil
        
        videoInput?.markAsFinished()
        
        assetWriter?.finishWriting { [weak self] in
            guard let self = self else { return }
            if self.assetWriter?.status == .completed {
                self.onRecordingComplete?(self.outputURL)
            } else if let error = self.assetWriter?.error {
                self.onRecordingError?("Recording failed: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func captureFrame() {
        guard isRecording,
              let assetWriter = assetWriter,
              let videoInput = videoInput,
              let adaptor = pixelBufferAdaptor,
              videoInput.isReadyForMoreMediaData else { return }
        
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - (startTime ?? currentTime)
        
        // Throttle to our target frame rate
        guard Double(frameCount) * frameDuration <= elapsed else { return }
        
        // Capture the current screen
        guard let pixelBuffer = captureScreenPixelBuffer() else { return }
        
        let presentationTime = CMTime(seconds: elapsed, preferredTimescale: 600)
        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        frameCount += 1
    }
    
    private func captureScreenPixelBuffer() -> CVPixelBuffer? {
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let width = Int(screenSize.width * scale)
        let height = Int(screenSize.height * scale)
        
        guard width > 0, height > 0 else { return nil }
        
        // Create pixel buffer
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        // BGRA pixel format: Blue, Green, Red, Alpha with alpha in the last byte
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let bitmapContext = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        // Draw the main window's layer hierarchy directly into the pixel buffer context
        // No flip needed - drawHierarchy renders in screen orientation
        bitmapContext.saveGState()
        // UIKit/Quartz2D coordinate system is flipped relative to CoreGraphics
        bitmapContext.translateBy(x: 0, y: CGFloat(height))
        bitmapContext.scaleBy(x: 1, y: -1)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            window.drawHierarchy(in: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height), afterScreenUpdates: false)
        }
        
        bitmapContext.restoreGState()
        
        return buffer
    }
    
    /// Save the recorded video to the camera roll.
    func saveToCameraRoll(completion: @escaping (Bool, String?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(false, "Camera roll access denied. Please enable it in Settings.")
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
            } completionHandler: { success, error in
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error?.localizedDescription ?? "Failed to save video.")
                }
            }
        }
    }
    
    /// Clean up the recorded file.
    func cleanupFile() {
        try? FileManager.default.removeItem(at: outputURL)
    }
}