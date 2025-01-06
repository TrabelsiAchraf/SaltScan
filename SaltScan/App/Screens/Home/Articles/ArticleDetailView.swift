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
                
                HStack {
                    Text("article.source.title")
                        .bold()
                        .multilineTextAlignment(.leading)
                    
                    Text(article.source.hint.localize)
                        .multilineTextAlignment(.leading)
                        .font(.body)
                        .foregroundColor(.blue)
                        .underline()
                        .onTapGesture {
                            if let url = URL(
                                string: article.source.link.localize
                            ) {
                                UIApplication.shared.open(url)
                            }
                        }
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ArticleDetailView(
        article: .init(
            title: "Le sel, ami ou ennemi ?",
            teaser: "Découvrez comment le sel peut affecter votre santé.",
            content: "Le sel est essentiel...",
            illustration: "illustration_01",
            source: (
                hint: "WHO Website",
                link: "https://www.who.int/news-room/fact-sheets/detail/salt-reduction"
            )
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
            illustration: "illustration_01",
            source: (
                hint: "WHO Website",
                link: "https://www.who.int/news-room/fact-sheets/detail/salt-reduction"
            )
        )
    )
    .preferredColorScheme(.dark)
    .environment(\.locale, Locale(identifier: "en"))
}
