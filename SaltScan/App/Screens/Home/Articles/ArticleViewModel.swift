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
                content: """
                Le sel est un ingrédient essentiel à notre alimentation, mais saviez-vous qu’il peut être aussi dangereux qu’utile ? En quantité modérée, il aide à maintenir l’équilibre des fluides dans notre corps et soutient le bon fonctionnement des nerfs et des muscles. Cependant, une consommation excessive de sel est associée à des risques accrus d’hypertension artérielle, de maladies cardiovasculaires et d’ostéoporose.
                
                Réduire votre consommation de sel peut être un premier pas vers une meilleure santé. Limitez les plats préparés et privilégiez les aliments frais, moins riches en sodium.
                
                Source suggérée : Organisation mondiale de la santé (OMS), www.who.int
                """,
                illustration: "illustration_01"
            ),
            Article(
                title: "Quelle quantité de sel consommez-vous ?",
                teaser: "Quelle quantité de sel est réellement nécessaire pour rester en bonne santé ?",
                content: """
                Selon les experts, un adulte ne devrait pas consommer plus de 5 g de sel par jour (environ une cuillère à café). Pourtant, dans de nombreux pays, la consommation moyenne dépasse largement cette recommandation, atteignant parfois 9 à 12 g par jour.
                
                Pourquoi est-ce un problème ? Une consommation excessive surcharge les reins et favorise la rétention d’eau, ce qui augmente la pression artérielle. En revanche, réduire sa consommation à moins de 5 g par jour peut réduire considérablement le risque de maladies cardiovasculaires.
                
                Conseil : Vérifiez les étiquettes des produits que vous achetez. Vous serez surpris de découvrir que le sel est caché dans de nombreux aliments transformés !
                """,
                illustration: "illustration_02"
            ),
            Article(
                title: "Le sel caché dans vos aliments préférés",
                teaser: "Apprenez à détecter le sel caché dans les aliments transformés.",
                content: """
                Vous ne voyez peut-être pas le sel que vous consommez, mais il est partout ! Les aliments transformés comme les soupes en conserve, les sauces, les snacks ou encore le pain sont souvent riches en sel. Par exemple, une portion de céréales pour le petit-déjeuner peut contenir jusqu’à 1 g de sel, soit 20 % de l’apport recommandé quotidiennement.
                
                Astuce : Lisez attentivement les étiquettes nutritionnelles. Les termes comme “sodium” ou “Na” indiquent la présence de sel. Pour une estimation rapide, 1 g de sodium équivaut à environ 2,5 g de sel.
                
                Source suggérée : Food and Drug Administration (FDA), www.fda.gov
                """,
                illustration: "illustration_03"
            ),
            Article(
                title: "Comment réduire sa consommation de sel ?",
                teaser: "Quelques astuces simples pour manger moins salé au quotidien.",
                content: """
                Vous voulez réduire votre consommation de sel sans sacrifier la saveur de vos plats ? Essayez ces astuces :
                    •    Remplacez le sel par des herbes et des épices comme le basilic, le thym, le curcuma ou le cumin pour relever vos plats.
                    •    Évitez les produits transformés : optez pour des aliments frais et non transformés.
                    •    Goûtez avant de saler : de nombreuses personnes ajoutent du sel sans même goûter leur plat.
                    •    Choisissez des alternatives faibles en sel : de plus en plus de marques proposent des versions réduites en sodium de leurs produits phares.
                
                Réduire votre consommation de sel est un processus graduel, mais chaque petit effort compte pour votre santé.
                """,
                illustration: "illustration_04"
            )
        ]
    }
}
