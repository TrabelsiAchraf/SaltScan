//
//  PrimaryButton.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI

struct PrimaryButton: View {
    let content: LocalizedStringKey
    let color: Color
    var action: () -> Void
    
    init(
        content: LocalizedStringKey,
        color: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.content = content
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(
            action: action,
            label: {
                Text(content)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color)
                    )
                    .foregroundColor(.white)
            }
        )
    }
}

#Preview {
    PrimaryButton(
        content: "onboarding.button.start",
        action: {}
    )
    .padding()
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    PrimaryButton(
        content: "onboarding.button.start",
        action: {}
    )
    .padding()
    .preferredColorScheme(.dark)
    .environment(\.locale, Locale(identifier: "en"))
}
