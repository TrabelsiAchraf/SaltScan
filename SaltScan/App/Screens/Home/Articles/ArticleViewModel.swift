//
//  ArticleViewModel.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import Foundation

final class ArticleViewModel: ObservableObject {
    @Published var articles: [Article] = []

    func loadArticles() {
        articles = [
            Article(
                title: "Le sel, ami ou ennemi ?",
                teaser: "Découvrez comment le sel peut affecter votre santé.",
                content: "Le sel est essentiel...",
                illustration: "illustration_01"
            ),
            Article(
                title: "Consommation journalière",
                teaser: "Quelle quantité de sel consommez-vous ?",
                content: "Il est recommandé...",
                illustration: "illustration_02"
            ),
            Article(
                title: "Sel caché dans les aliments",
                teaser: "Apprenez à détecter le sel caché.",
                content: "De nombreux produits...",
                illustration: "illustration_03"
            )
        ]
    }
}
