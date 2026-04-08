//
//  ProductScannerView.swift
//  SaltScan
//
//  Refreshed scanner overlay: animated laser line, cut-out viewfinder, and a
//  detent-aware bottom sheet that surfaces the refreshed ProductDetailView.
//

import SwiftUI
import AudioToolbox
import AVFoundation

struct ProductScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var captureSession = AVCaptureSession()
    @State private var laserOffset: CGFloat = -90
    @State private var showDetail: Bool = false
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            ScannerView(captureSession: $captureSession) { barcode in
                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {
                    haptic.impactOccurred()
                    scannedCode = barcode
                    showDetail = true
                    captureSession.stopRunning()
                }
            }
            .edgesIgnoringSafeArea(.all)

            dimmedOverlay

            viewfinder

            VStack {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding(SSSpacing.md)
                Spacer()
                Text("scanner.instructions")
                    .font(SSFont.subheadline().weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, SSSpacing.md)
                    .padding(.vertical, SSSpacing.xs)
                    .background(.black.opacity(0.45))
                    .clipShape(Capsule())
                    .padding(.bottom, SSSpacing.xxl)
            }
        }
        .sheet(isPresented: $showDetail, onDismiss: resumeCapture) {
            if let scannedCode {
                NavigationStack {
                    ProductDetailView(barcode: scannedCode)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("result.product.button.rescan") {
                                    showDetail = false
                                }
                            }
                        }
                }
                .presentationDetents([.large, .medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            haptic.prepare()
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                laserOffset = 90
            }
        }
    }

    // MARK: - Pieces

    private var dimmedOverlay: some View {
        Rectangle()
            .fill(.black.opacity(0.55))
            .mask {
                Rectangle()
                    .overlay(
                        RoundedRectangle(cornerRadius: SSRadius.lg)
                            .frame(width: 280, height: 200)
                            .blendMode(.destinationOut)
                    )
                    .compositingGroup()
            }
            .ignoresSafeArea()
    }

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SSRadius.lg)
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 3)
                .frame(width: 280, height: 200)

            Rectangle()
                .fill(LinearGradient(
                    colors: [.ssPrimary.opacity(0), .ssPrimary, .ssPrimary.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: 260, height: 2)
                .offset(y: laserOffset)
                .mask(RoundedRectangle(cornerRadius: SSRadius.lg).frame(width: 280, height: 200))
        }
    }

    private var closeButton: some View {
        Button {
            haptic.impactOccurred()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .padding(SSSpacing.sm)
                .background(.black.opacity(0.4))
                .clipShape(Circle())
        }
    }

    private func resumeCapture() {
        scannedCode = nil
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
}
