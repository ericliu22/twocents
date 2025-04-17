//
//  AuthenticationView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import SwiftUI

struct AuthenticationView: View {
    
    @Environment(AppModel.self) var appModel
    @State private var animateGradient: Bool = false
    
    //@TODO: Change welcome messages
    private let welcomeMessages = [
        "The For Us Page",
        "Share your world",
        "Simple. Curated. Fun.",
        "Keep up with the times!",
        "Effortless connection",
        "The ultimate brain dump",
        "Your space to shine",
        "Connect, Create, Celebrate",
        "Curate your vibe",
        "Express without limits",
        "Stay inspired, stay connected",
        "Your world in a snapshot",
        "Share. Spark. Smile.",
        "The heartbeat of your day",
        "Moments made memorable",
        "Where ideas come alive"
    ]
    
    @State private var shownMessages: [String] = []
    @State private var welcomeMessage = ""
    @State private var currentText = ""
    
    // A cancellable task for the typing animation.
    @State private var typingTask: Task<Void, Never>? = nil
    
    /// Picks a new message from the list that hasn’t been shown yet.
    private func showNewMessage() {
        if shownMessages.count == welcomeMessages.count {
            shownMessages.removeAll()
        }
        var randomMessage: String
        repeat {
            randomMessage = welcomeMessages.randomElement() ?? ""
        } while shownMessages.contains(randomMessage)
        
        shownMessages.append(randomMessage)
        welcomeMessage = randomMessage
    }
    
    /// Starts the typing animation using Swift concurrency.
    private func startTypingAnimation() {
        // Cancel any previous animation to avoid overlapping tasks.
        typingTask?.cancel()
        currentText = ""
        
        typingTask = Task {
            while !Task.isCancelled {
                // Type out the message character-by-character.
                for character in welcomeMessage {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                    if Task.isCancelled { break }
                    await MainActor.run {
                        currentText.append(character)
                    }
                }
                
                if Task.isCancelled { break }
                
                // Wait 2 seconds after completing the message.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { break }
                
                // Clear the current text, pick a new message, and restart typing.
                await MainActor.run {
                    currentText = ""
                    showNewMessage()
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: 150)
            
            VStack {
                Image("TwoCentsLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                // The text that displays the typing animation.
                VStack(alignment: .leading) {
                    Text(currentText)
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .fontWeight(.regular)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            NavigationLink {
                SignInEmailView()
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.label))
                    .cornerRadius(10)
            }
            
            NavigationLink {
                RegisterEmailView()
            } label: {
                Text("New? Ugh. Create a new account")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer().frame(height: 50)
        }
        .padding(.horizontal)
        .background(Color("bg"))
        // Start the animation when the view appears.
        .onAppear {
            showNewMessage()
            startTypingAnimation()
        }
        // Cancel the typing task when the view disappears.
        .onDisappear {
            typingTask?.cancel()
            typingTask = nil
        }
    }
}
