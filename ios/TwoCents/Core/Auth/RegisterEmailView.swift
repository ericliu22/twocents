//
//  RegisterEmailView.swift
//  TwoCents
//
//  Created by jonathan on 8/11/23.
//

import SwiftUI

struct RegisterEmailView: View {
    @Environment(\.presentationMode) var presentation
    @Environment(AppModel.self) var appModel

    @State private var viewModel = RegisterEmailViewModel()
    @State private var doneRegistering = false

    // 1. Define an enum for all focusable fields.
    enum Field: Hashable {
        case username, email, password, confirmPassword
    }
    
    // 1. Use @FocusState to track current focused field.
    @FocusState private var focusedField: Field?

    var body: some View {
        // Wrap in ScrollViewReader so we can scroll programmatically
            ScrollView {
                VStack {
                    Spacer().frame(height: 50)
                    
                    Image("TwoCentsLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    
                    Spacer().frame(height: 25)
                    
                    // Username TextField
                    TextField("Username", text: $viewModel.username)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)       // Set return key label
                        .onSubmit {
                            // Move focus to the email field
                            focusedField = .email
                        }
                    
                    // Email TextField
                    TextField("Email", text: $viewModel.email)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .frame(height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            // Move focus to the password field
                            focusedField = .password
                        }
                    
                    // Password SecureField
                    SecureField("Password", text: $viewModel.password)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .frame(height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit {
                            // Move focus to the confirm password field
                            focusedField = .confirmPassword
                        }
                    
                    // Confirm Password SecureField (Last text field)
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .frame(height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.done)       // Return key displays "Done"
                        .onSubmit {
                            // Dismiss the keyboard by clearing focus.
                            focusedField = nil
                        }
                    
                    Spacer().frame(height: 25)
                    
                    Button {
                        // Sign Up action
                        Task {
                            do {
                                appModel.currentUser = try await viewModel.signUp()
                                appModel.activeSheet  = nil
                                requestNotificationAuthorization()
                                doneRegistering = true
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(UIColor.label))
                    .frame(height: 55)
                    .cornerRadius(10)
                    
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding(.top)
                        .font(.caption)
                    
                    // Anchor view for scrolling
                    Color.clear.frame(height: 1)
                        .id("BottomAnchor")
                } // End VStack
                .padding()
                .navigationTitle("Welcome, I guess?")
                .tint(Color(UIColor.label))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading:
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                        .onTapGesture {
                            self.presentation.wrappedValue.dismiss()
                        }
                )
            } // End ScrollView
            .scrollDismissesKeyboard(.interactively)
    }
}

struct SignUpEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterEmailView()
        }
    }
}
