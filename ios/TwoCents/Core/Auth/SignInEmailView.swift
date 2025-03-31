//
//  SignInEmailView.swift
//  TwoCents
//
//  Created by jonathan on 8/2/23.
//

import SwiftUI


struct SignInEmailView: View {
    @Environment(\.presentationMode) var presentation
    @Environment(AppModel.self) var appModel
    @State private var viewModel = SignInEmailViewModel()
    
    var body: some View {
        ScrollView{
      
        
        VStack {
            Spacer()
                .frame(height:100)
            
            Image("TwoCentsLogo")
                .resizable() // Makes the image resizable
                .scaledToFit() // Maintains the aspect ratio
                .frame(width: 100, height: 100) // Sets the desired size
            
            Spacer()
                .frame(height:50)
            
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
            
            Button {
                Task {
                    do {
                        appModel.currentUser = try await viewModel.signIn()
                        requestNotificationAuthorization()
                        appModel.activeSheet = nil
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Text("Sign In")
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
            
        }
        .padding()
        .navigationTitle("Back to the chaos")
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

/*
struct SignInEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack{
//            SignInEmailView(showSignInView: .constant(false),showCreateProfileView: .constant(false))
            SignInEmailView(appModel.activeSheet: .constant(nil))
        }
    }
}
*/
