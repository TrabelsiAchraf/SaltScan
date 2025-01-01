//
//  ContactUsView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import SwiftUI

struct ContactUsView: View {
    @State private var showingSentAlert = false
    @State private var showingLimitReachedAlert = false
    @State private var showingMailView = false
    @State private var selectedHelpReason = "contactUs.helpReasons.01".localize
    @State private var tellUsTextField: String = ""
    @State private var selectedFeedback: EmojyState = .happy
    private let helpReasons = [
        "contactUs.helpReasons.01".localize,
        "contactUs.helpReasons.02".localize,
        "contactUs.helpReasons.03".localize,
        "contactUs.helpReasons.04".localize,
        "contactUs.helpReasons.05".localize
    ]
    private enum EmojyState: String {
        case veryHappy = "😁"
        case happy = "🙂"
        case unsatisfied = "😑"
        case unhappy = "😕"
        case angry = "😤"
    }
    private var feedbacks: [EmojyState] = [.angry, .unhappy, .unsatisfied, .happy, .veryHappy]
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Picker("contactUs.helpReasons.title", selection: $selectedHelpReason) {
                        ForEach(helpReasons, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    TextField("contactUs.helpReasons.textfield", text: $tellUsTextField)
                    
                    Button {
                        
                    } label: {
                        Text("contactUs.FAQ.title")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("contactUs.howDoYouFeel.title")
                        Picker("contactUs.howCanWeHelp.title", selection: $selectedFeedback) {
                            ForEach(feedbacks, id: \.self) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 55, height: 55)
                                    .overlay(
                                        Text($0.rawValue)
                                            .font(.title)
                                    )
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } header: {
                    Text("contactUs.section.title")
                } footer: {
                    VStack {
                        PrimaryButton(
                            content: "contactUs.button.send",
                            color: tellUsTextField.isEmpty ? .gray : .blue,
                            action: {
                                if canSendMailToday() {
                                    showingMailView = true
                                    incrementMailCount()
                                } else {
                                    showingLimitReachedAlert = true
                                }
                            }
                        )
                        .padding()
                        .disabled(tellUsTextField.isEmpty)
                    }
                    .frame(width: UIScreen.main.bounds.width, alignment: .center)
                }
            }
        }
        .sheet(isPresented: $showingMailView) {
            MailView(
                subject: selectedHelpReason,
                messageBody: prepareMailMessageBody()
            ) { mailStatus in
                if mailStatus == .sent {
                    showingSentAlert = true
                }
                showingMailView = false
            }
        }
        .alert("contactUs.sent.alert.title", isPresented: $showingSentAlert) {
            Button("contactUs.sent.alert.ok", role: .cancel) { }
        }
        .alert("contactUs.limitReached.alert.title", isPresented: $showingLimitReachedAlert) {
            Button("contactUs.limitReached.alert.ok", role: .cancel) { }
        }
    }
    
    // MARK: - Private
    
    private func prepareMailMessageBody() -> String {
        tellUsTextField + "\n\n" + String(
            format: "contactUs.howDoIFeel.mail".localize,
            selectedFeedback.rawValue
        )
    }
    
    private func canSendMailToday() -> Bool {
        let lastSentDate = UserDefaults.standard.object(forKey: "lastSentDate") as? Date ?? Date.distantPast
        let currentDate = Calendar.current.startOfDay(for: Date())

        if !Calendar.current.isDate(lastSentDate, inSameDayAs: currentDate) {
            UserDefaults.standard.set(0, forKey: "sentMailsToday")
        }

        let sentMailsToday = UserDefaults.standard.integer(forKey: "sentMailsToday")
        return sentMailsToday < 3
    }

    private func incrementMailCount() {
        let sentMailsToday = UserDefaults.standard.integer(forKey: "sentMailsToday")
        UserDefaults.standard.set(sentMailsToday + 1, forKey: "sentMailsToday")
        UserDefaults.standard.set(Date(), forKey: "lastSentDate")
    }
}

#Preview {
    ContactUsView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    ContactUsView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}
