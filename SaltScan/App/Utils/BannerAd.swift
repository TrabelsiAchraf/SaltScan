//
//  BannerAd.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 31/12/2024.
//

import SwiftUI
import GoogleMobileAds

struct BannerContentView: View {
    var body: some View {
        GeometryReader { geometry in
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)
            
            VStack {
                Spacer()
                BannerView(adSize)
                    .frame(height: adSize.size.height)
            }
        }
    }
}

#Preview {
    BannerContentView()
}

// MARK: - BannerView

private struct BannerView: UIViewRepresentable {
    let adSize: GADAdSize
    
    init(_ adSize: GADAdSize) {
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> UIView {
        // Wrap the GADBannerView in a UIView. GADBannerView automatically reloads a new ad when its
        // frame size changes; wrapping in a UIView container insulates the GADBannerView from size
        // changes that impact the view returned from makeUIView.
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }
    
    func makeCoordinator() -> BannerCoordinator {
        BannerCoordinator(self)
    }
    
    class BannerCoordinator: NSObject, GADBannerViewDelegate {
        
        private(set) lazy var bannerView: GADBannerView = {
            let banner = GADBannerView(adSize: parent.adSize)
            banner.adUnitID = AdMobConstants.adUnitID_prod
            banner.load(GADRequest())
            banner.delegate = self
            return banner
        }()
        
        let parent: BannerView
        
        init(_ parent: BannerView) {
            self.parent = parent
        }
        
        // MARK: - GADBannerViewDelegate methods
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            debugPrint("DID RECEIVE AD.")
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            debugPrint("FAILED TO RECEIVE AD: \(error.localizedDescription)")
        }
    }
}
