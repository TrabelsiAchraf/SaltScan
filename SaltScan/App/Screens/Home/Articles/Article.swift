//
//  Article.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import Foundation

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let teaser: String
    let content: String
    let illustration: String
    let source: (hint: String, link: String)
}
