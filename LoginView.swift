//
//  LoginView.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//
import SwiftUI
import CoreData

struct LoginView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateToRegister: Bool = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.healixBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo
                Text("Healix")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.healixDarkBlue)
                    .padding(.top, 80)
                
                // Login Form
                VStack(spacing: 20) {
                    // Username Field
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    // Password Field
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Password", text: $password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.healixTextSecondary)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    
                    // Login Button
                    Button(action: loginUser) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.healixBlue)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                    
                    // Register Navigation
                    NavigationLink(destination: RegistrationView()) {
                        Text("Don't have an account? Register")
                            .font(.subheadline)
                            .foregroundColor(.healixBlue)
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Login Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Methods
    private func loginUser() {
        // Validate input
        guard !username.isEmpty && !password.isEmpty else {
            alertMessage = "Please enter both username and password."
            showAlert = true
            return
        }
        
        // Check credentials against stored data
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            let users = try viewContext.fetch(request)
            
            if let user = users.first, user.password == password {
                // Successfully logged in
                UserDefaults.standard.set(user.id?.uuidString, forKey: "loggedInUserId")
                
                // Switch to MainView
                if let window = UIApplication.shared.windows.first {
                    window.rootViewController = UIHostingController(
                        rootView: NavigationStack {
                            MainView()
                                .environment(\.managedObjectContext, viewContext)
                        }
                    )
                    window.makeKeyAndVisible()
                }
            } else {
                // Invalid credentials
                alertMessage = "Invalid username or password."
                showAlert = true
            }
        } catch {
            alertMessage = "An error occurred. Please try again."
            showAlert = true
            print("Error fetching user: \(error)")
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
