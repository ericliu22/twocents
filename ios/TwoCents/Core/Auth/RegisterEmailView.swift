//
//  SignUpEmailView.swift
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
    
    var body: some View {
        
        ScrollView{
        VStack {
            Spacer()
                .frame(height:50)
            
            Image("TwoCentsLogo")
                .resizable() // Makes the image resizable
                .scaledToFit() // Maintains the aspect ratio
                .frame(width: 100, height: 100) // Sets the desired size
            
            
            Spacer()
                .frame(height:25)
            
            //Name Textfield
            TextField("Name", text: $viewModel.name)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .padding()
                .frame(height: 50)  // Set a fixed height for the text field
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            
            //Username Textfield
            TextField("Username", text: $viewModel.username)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            
            //Email Textfield
            
            TextField("Email", text: $viewModel.email)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .padding()
                .frame(height: 50)  // Set a fixed height for the text field
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            
            
            //Password Textfield
            SecureField("Password", text: $viewModel.password)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .padding()
                .frame(height: 50)  // Set a fixed height for the text field
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            
            //Confirm Password Textfield
            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .padding()
                .frame(height: 50)  // Set a fixed height for the text field

                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            
            Button {
                //signUp
                Task {
                    do {
                        try await viewModel.signUp()
                        appModel.activeSheet  = nil
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
            
//            NavigationLink(
//                destination:
//                    CustomizeProfileView()
//                    .navigationBarBackButtonHidden(true) ,
//                isActive: $doneRegistering
//            ) {
//                EmptyView()
//            }
            
            
            
            
            
        }
        
        
        .padding()
        .navigationTitle("Welcome, I guess?")
        .tint(Color(UIColor.label))
        .navigationBarTitleDisplayMode(.inline)
        //make back button black... (Gotta have the enviorment line on top)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
                                Image(systemName: "chevron.backward")
            .foregroundColor(Color(UIColor.label))
            .onTapGesture {
                self.presentation.wrappedValue.dismiss()
            }
        )
        
        
            
        }
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
