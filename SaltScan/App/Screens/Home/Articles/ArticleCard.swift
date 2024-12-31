//
//  ArticleCard.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import SwiftUI

struct ArticleCard: View {
    let article: Article
    
    var body: some View {
        NavigationLink(destination: ArticleDetailView(article: article)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(article.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                    Text(article.teaser)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    Spacer()
                }
                .padding()
                
                Image(article.illustration)
                    .resizable()
                    .scaledToFit()
            }
            .padding(10)
            .background(
                content: {
                    RoundedRectangle(
                        cornerSize: .init(
                            width: 10,
                            height: 10
                        )
                    )
                    .fill(.cardBackground)
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ArticleCard(
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
    ArticleCard(
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
