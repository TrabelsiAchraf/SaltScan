//
//  ProductScannerView.swift
//  SaltScan
//
//  Refreshed scanner overlay: animated laser line, cut-out viewfinder, and a
//  detent-aware bottom sheet that surfaces the refreshed ProductDetailView.
//  A "search by name" shortcut covers products without a readable barcode.
//

import SwiftUI
import AudioToolbox
import AVFoundation

/// Wrapper used as the sheet item — driving the result sheet by item rather
/// than a separate `Bool` + optional barcode eliminates the one-frame race
/// where the sheet's body would render with `scannedCode == nil` on the very
/// first presentation.
private struct ScannedBarcode: Identifiable, Equatable {
    let id = UUID()
    let value: String
}

/// Tiny thread-safe one-shot latch backing the capture de-dupe.
private final class AtomicBool {
    private var value: Bool
    private let lock = NSLock()
    init(_ value: Bool) { self.value = value }
    func compareAndSet(expected: Bool, new: Bool) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard value == expected else { return false }
        value = new
        return true
    }
    func set(_ new: Bool) { lock.lock(); value = new; lock.unlock() }
}

struct ProductScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scanned: ScannedBarcode?
    @State private var showSearch = false
    @State private var captureSession = AVCaptureSession()
    @State private var laserOffset: CGFloat = -90
    @State private var didCapture = AtomicBool(false)
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            ScannerView(captureSession: $captureSession) { barcode in
                // AVFoundation can deliver several metadata callbacks before
                // the capture session actually stops. Use an atomic flag to
                // accept exactly one barcode per scan session, otherwise the
                // sheet item churns and visibly re-presents.
                guard didCapture.compareAndSet(expected: false, new: true) else { return }

                let session = captureSession
                DispatchQueue.global(qos: .userInitiated).async {
                    session.stopRunning()
                }
                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {
                    Task { @MainActor in
                        haptic.impactOccurred()
                        scanned = ScannedBarcode(value: barcode)
                    }
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
                    .padding(.bottom, SSSpacing.sm)
                searchByNameButton
                    .padding(.bottom, SSSpacing.xxl)
            }
            .sheet(isPresented: $showSearch) {
                ProductSearchView()
            }
        }
        .sheet(item: $scanned, onDismiss: resumeCapture) { item in
            NavigationStack {
                ProductDetailView(barcode: item.value)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("result.product.button.rescan") {
                                scanned = nil
                            }
                        }
                    }
            }
            .presentationDetents([.large, .medium])
            .presentationDragIndicator(.visible)
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

    private var searchByNameButton: some View {
        Button {
            haptic.impactOccurred()
            showSearch = true
        } label: {
            Label("scanner.searchByName", systemImage: "magnifyingglass")
                .font(SSFont.subheadline().weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, SSSpacing.md)
                .padding(.vertical, SSSpacing.xs)
                .background(.white.opacity(0.18))
                .clipShape(Capsule())
        }
    }

    private func resumeCapture() {
        scanned = nil
        didCapture.set(false)
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
}
