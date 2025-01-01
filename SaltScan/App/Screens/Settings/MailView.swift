//
//  MailView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 31/12/2024.
//

import MessageUI
import SwiftUI

enum MailStatus {
    case sent
    case cancelled
    case failed
}

struct MailView: UIViewControllerRepresentable {
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            switch result {
            case .sent:
                self.parent.didFinish(.sent)
            case .cancelled, .saved:
                self.parent.didFinish(.cancelled)
            case .failed:
                self.parent.didFinish(.failed)
            default:
                self.parent.didFinish(.cancelled)
            }
            
            controller.dismiss(animated: true) {
                self.parent.didFinish(.cancelled)
            }
        }
    }
    
    let subject: String
    let messageBody: String
    var didFinish: (MailStatus) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.setToRecipients([Constants.contactMail])
        mailComposeViewController.setSubject(subject)
        mailComposeViewController.setMessageBody(messageBody, isHTML: false)
        mailComposeViewController.mailComposeDelegate = context.coordinator
        return mailComposeViewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
