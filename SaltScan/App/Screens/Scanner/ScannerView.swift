//
//  ScannerView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: ScannerView
        @Binding var captureSession: AVCaptureSession
        
        init(
            parent: ScannerView,
            captureSession: Binding<AVCaptureSession>
        ) {
            self.parent = parent
            self._captureSession = captureSession
        }
        
        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let barcode = metadataObject.stringValue
            else { return }
            
            parent.completion(barcode)
        }
    }
    
    @Binding var captureSession: AVCaptureSession
    var completion: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            parent: self,
            captureSession: $captureSession
        )
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            return vc
        }
        
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height
        )
        previewLayer.videoGravity = .resizeAspectFill
        
        let containerView = UIView(frame: vc.view.bounds)
        containerView.backgroundColor = .black
        containerView.layer.addSublayer(previewLayer)
        vc.view.addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor)
        ])
        
        containerView.layer.layoutSublayers()
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let containerView = uiViewController.view.subviews.first,
           let previewLayer = containerView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = containerView.bounds
        }
    }
}
