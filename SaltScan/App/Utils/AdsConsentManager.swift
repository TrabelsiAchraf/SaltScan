//
//  AdsConsentManager.swift
//  SaltScan
//
//  Gathers ad consent through Google's User Messaging Platform (required by
//  AdMob for users in the EEA, UK and Switzerland) before the Mobile Ads SDK
//  starts. Ads only load once `canRequestAds` is true; the SDK reports true
//  right away for users outside the regions where a consent form is required.
//
//  The GDPR message itself is configured in the AdMob console under
//  Privacy & messaging. Without one, `loadAndPresentIfRequired` is a no-op and
//  ads keep loading as before.
//

import Foundation
import UIKit
import GoogleMobileAds
import UserMessagingPlatform

@MainActor
final class AdsConsentManager: ObservableObject {
    static let shared = AdsConsentManager()

    @Published private(set) var canRequestAds = false
    @Published private(set) var isPrivacyOptionsRequired = false

    private var isMobileAdsStarted = false
    private var isGathering = false

    private init() {}

    /// Call once the UI is on screen: a view controller is needed to present the form.
    func gatherConsentIfNeeded() {
        guard !isGathering else { return }
        isGathering = true

        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
            Task { @MainActor in
                if let error {
                    debugPrint("UMP consent info update failed: \(error.localizedDescription)")
                    AdsConsentManager.shared.finishGathering()
                    return
                }
                guard let viewController = AdsConsentManager.topViewController() else {
                    AdsConsentManager.shared.finishGathering()
                    return
                }
                UMPConsentForm.loadAndPresentIfRequired(from: viewController) { formError in
                    Task { @MainActor in
                        if let formError {
                            debugPrint("UMP consent form failed: \(formError.localizedDescription)")
                        }
                        AdsConsentManager.shared.finishGathering()
                    }
                }
            }
        }

        // Consent gathered in a previous session: start ads without waiting.
        if UMPConsentInformation.sharedInstance.canRequestAds {
            startMobileAdsIfNeeded()
        }
    }

    /// Lets the user revisit their choice (UMP requires an entry point when applicable).
    func presentPrivacyOptions() {
        guard let viewController = Self.topViewController() else { return }
        UMPConsentForm.presentPrivacyOptionsForm(from: viewController) { error in
            if let error {
                debugPrint("UMP privacy options failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func finishGathering() {
        isGathering = false
        isPrivacyOptionsRequired =
            UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
        if UMPConsentInformation.sharedInstance.canRequestAds {
            startMobileAdsIfNeeded()
        }
    }

    private func startMobileAdsIfNeeded() {
        guard !isMobileAdsStarted else {
            canRequestAds = true
            return
        }
        isMobileAdsStarted = true
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["4812cfe835374af410fe16b30d8b1039"]
        GADMobileAds.sharedInstance().start { _ in
            Task { @MainActor in
                AdsConsentManager.shared.canRequestAds = true
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
