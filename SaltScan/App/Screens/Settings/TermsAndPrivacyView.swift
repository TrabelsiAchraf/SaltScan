//
//  TermsAndPrivacyView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 31/12/2024.
//

import SwiftUI

struct TermsAndPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("termsAndPrivacy.title")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("termsAndPrivacy.terms.title")
                    .font(.headline)
                    .padding(.bottom, 5)
                Text("termsAndPrivacy.terms.description")
                
                Divider().padding(.vertical)
                
                Text("termsAndPrivacy.privacy.title")
                    .font(.headline)
                    .padding(.bottom, 5)
                Text("termsAndPrivacy.privacy.description")
            }
            .padding()
        }
    }
}

#Preview {
    TermsAndPrivacyView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    TermsAndPrivacyView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
