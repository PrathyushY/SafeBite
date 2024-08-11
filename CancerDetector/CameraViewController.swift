//
//  CameraViewController.swift
//  CancerDetector
//
//  Created by Prathyush Yeturi on 8/11/24.
//

import UIKit
import SwiftUI
import AVFoundation

class CameraViewController: UIViewController {
    private var permissionGranted = false // Flag for permission
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil // For view dimesions
    
    override func viewDidLoad() {
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        
        switch UIDevice.current.orientation {
            // Home button on top
            case UIDeviceOrientation.portraitUpsideDown:
                self.previewLayer.connection?.videoRotationAngle = 180
                
            // Home button on right
            case UIDeviceOrientation.landscapeLeft:
                self.previewLayer.connection?.videoRotationAngle = 180
                
            // Home button on left
            case UIDeviceOrientation.landscapeRight:
                self.previewLayer.connection?.videoRotationAngle = 90
            
            // Home button at bottom
            case UIDeviceOrientation.portrait:
                self.previewLayer.connection?.videoRotationAngle = 0
                
            default:
                break
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
        case .authorized:
            permissionGranted = true
            
            // Permission has not been requested yet
        case .notDetermined:
            requestPermission()
            
        default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        // Camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        // Preview layer
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
        previewLayer.connection?.videoRotationAngle = 90
        
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
}

struct HostedCameraViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
