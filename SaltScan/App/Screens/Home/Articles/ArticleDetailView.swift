//
//  ArticleDetailView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(article.content)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("article.title")
    }
}

#Preview {
    ArticleDetailView(
        article: .init(
            title: "Le sel, ami ou ennemi ?",
            teaser: "Découvrez comment le sel peut affecter votre santé.",
            content: "Le sel est essentiel...",
            illustration: "illustration_01"
        )
    )
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    ArticleDetailView(
        article: .init(
            title: "Le sel, ami ou ennemi ?",
            teaser: "Découvrez comment le sel peut affecter votre santé.",
            content: "Le sel est essentiel...",
            illustration: "illustration_01"
        )
    )
    .preferredColorScheme(.dark)
    .environment(\.locale, Locale(identifier: "en"))
}
