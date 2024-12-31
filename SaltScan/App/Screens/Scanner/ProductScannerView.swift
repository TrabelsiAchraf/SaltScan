//
//  ProductScannerView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import SwiftUI
import AudioToolbox
import AVFoundation

struct ProductScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var captureSession = AVCaptureSession()
    private let buttonTapImpactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ZStack {
            ScannerView(captureSession: $captureSession) { barcode in
                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {
                    scannedCode = barcode
                    captureSession.stopRunning()
                }
            }
            .edgesIgnoringSafeArea(.all)
            .overlay {
                Image(systemName: "barcode.viewfinder")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .symbolEffect(.bounce, value: scannedCode)
                    .foregroundStyle(.clear, .white)
                    .scaledToFit()
                    .frame(width: 200)
            }
            .onChange(of: scannedCode) { oldValue, newValue in
                if newValue == nil {
                    DispatchQueue.global(qos: .background).async {
                        captureSession.startRunning()
                    }
                }
            }
            
            VStack {
                Spacer()
                if scannedCode != nil {
                    ResultView(scannedCode: $scannedCode)
                }
            }
            
            VStack {
                HStack {
                    Button(
                        action: {
                            buttonTapImpactFeedback.impactOccurred()
                            dismiss()
                        },
                        label: {
                            Image(systemName: "xmark")
                                .font(.largeTitle)
                                .bold()
                                .foregroundStyle(.white)
                        }
                    )
                    Spacer()
                }
                Spacer()
            }
            .padding(.all, 16)
        }
        .onAppear {
            prepareHaptic()
        }
    }
    
    // MARK: - Private
    
    private func prepareHaptic() {
        buttonTapImpactFeedback.prepare()
    }
}

#Preview {
    ProductScannerView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    ProductScannerView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
