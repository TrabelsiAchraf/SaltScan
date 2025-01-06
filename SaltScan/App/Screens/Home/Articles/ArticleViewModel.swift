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
                title: "article01.title".localize,
                teaser: "article01.teaser".localize,
                content: "article01.content".localize,
                illustration: "illustration_01",
                source: (
                    hint: "article01.source.hint",
                    link: "article01.source.link"
                )
            ),
            Article(
                title: "article02.title".localize,
                teaser: "article02.teaser".localize,
                content: "article02.content".localize,
                illustration: "illustration_02",
                source: (
                    hint: "article02.source.hint",
                    link: "article02.source.link"
                )
            ),
            Article(
                title: "article03.title".localize,
                teaser: "article03.teaser".localize,
                content: "article03.content".localize,
                illustration: "illustration_03",
                source: (
                    hint: "article03.source.hint",
                    link: "article03.source.link"
                )
            ),
            Article(
                title: "article04.title".localize,
                teaser: "article04.teaser".localize,
                content: "article04.content".localize,
                illustration: "illustration_04",
                source: (
                    hint: "article04.source.hint",
                    link: "article04.source.link"
                )
            )
        ]
    }
}
