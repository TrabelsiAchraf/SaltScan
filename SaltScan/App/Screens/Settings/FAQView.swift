//
//  FAQView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 31/12/2024.
//

import SwiftUI

struct FAQView: View {
    let faqs = [
        (
            "FAQ.description.item01.title".localize,
            "FAQ.description.item01.description".localize
        ),
        (
            "FAQ.description.item02.title".localize,
            "FAQ.description.item02.description".localize
        ),
        (
            "FAQ.description.item03.title".localize,
            "FAQ.description.item03.description".localize
        ),
        (
            "FAQ.description.item04.title".localize,
            "FAQ.description.item04.description".localize
        ),
        (
            "FAQ.description.item05.title".localize,
            "FAQ.description.item05.description".localize
        ),
        (
            "FAQ.description.item06.title".localize,
            "FAQ.description.item06.description".localize
        ),
        (
            "FAQ.description.item07.title".localize,
            "FAQ.description.item07.description".localize
        ),
        (
            "FAQ.description.item08.title".localize,
            "FAQ.description.item08.description".localize
        ),
        (
            "FAQ.description.item09.title".localize,
            "FAQ.description.item09.description".localize
        ),
        (
            "FAQ.description.item10.title".localize,
            "FAQ.description.item10.description".localize
        )
    ]
    
    var body: some View {
        Text("FAQ.title")
            .font(.title)
            .fontWeight(.bold)
            .padding(.top)
        
        List(faqs, id: \.0) { faq in
            VStack(alignment: .leading, spacing: 10) {
                Text(faq.0)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(faq.1)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil) // To allow multiline description
            }
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    FAQView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    FAQView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
