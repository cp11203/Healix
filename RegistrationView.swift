//
//  RegistrationView.swift
//  Healix
//

import SwiftUI
import CoreData

struct RegistrationView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    // Account Information
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Demographic Information
    @State private var age: String = ""
    @State private var gender: String = "Select"
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var bloodType: String = "Select"
    @State private var allergies: String = ""
    @State private var chronicConditions: String = ""
    
    // UI State
    @State private var currentStep: Int = 1
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var navigateToLogin: Bool = false
    @State private var isRegistering: Bool = false
    
    // Gender and Blood Type Options
    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let bloodTypeOptions = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown"]
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Header with Progress Indicators
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button(action: {
                        if currentStep > 1 {
                            currentStep -= 1
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.healixBlue)
                    }
                    
                    Spacer()
                    
                    Text("Step \(currentStep) of 2")
                        .font(.headline)
                        .foregroundColor(.healixTextSecondary)
                }
                
                Text(currentStep == 1 ? "Create Account" : "Demographic Information")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.healixTextPrimary)
                
                ProgressBar(value: Double(currentStep) / 2.0)
                    .frame(height: 6)
                    .padding(.top, 5)
            }
            .padding()
            
            // Form Content
            ScrollView {
                VStack(spacing: 25) {
                    if currentStep == 1 {
                        // Account Information Form
                        accountInformationForm
                    } else {
                        // Demographic Information Form
                        demographicInformationForm
                    }
                }
                .padding()
            }
            
            // Navigation Button
            Button(action: {
                if currentStep == 1 {
                    if validateAccountInfo() {
                        currentStep += 1
                    }
                } else {
                    registerUser()
                }
            }) {
                if isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.healixBlue)
                        .cornerRadius(10)
                } else {
                    Text(currentStep == 1 ? "Next" : "Register")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.healixBlue)
                        .cornerRadius(10)
                }
            }
            .disabled(isRegistering)
            .padding()
        }
        .background(Color.healixBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if navigateToLogin {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .onAppear {
            // Check if Core Data is properly initialized
            if !PersistenceController.shared.isStoreLoaded {
                alertTitle = "Database Error"
                alertMessage = "Database is not properly initialized. Please restart the app."
                showAlert = true
            }
        }
    }
    
    // MARK: - Subviews
    
    // Account Information Form
    private var accountInformationForm: some View {
        VStack(spacing: 20) {
            // Username Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Username")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                TextField("Enter username", text: $username)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                SecureField("Enter password", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Confirm Password")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                SecureField("Confirm password", text: $confirmPassword)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // Demographic Information Form
    private var demographicInformationForm: some View {
        VStack(spacing: 20) {
            // Age Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Age")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                TextField("Enter age", text: $age)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Gender Selection
            VStack(alignment: .leading, spacing: 5) {
                Text("Gender")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Menu {
                    ForEach(genderOptions, id: \.self) { option in
                        Button(action: {
                            gender = option
                        }) {
                            Text(option)
                        }
                    }
                } label: {
                    HStack {
                        Text(gender)
                            .foregroundColor(gender == "Select" ? .gray : .healixTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            
            // Height and Weight Fields
            HStack(spacing: 15) {
                // Height Field
                VStack(alignment: .leading, spacing: 5) {
                    Text("Height (cm)")
                        .font(.headline)
                        .foregroundColor(.healixTextPrimary)
                    
                    TextField("Enter height", text: $height)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // Weight Field
                VStack(alignment: .leading, spacing: 5) {
                    Text("Weight (kg)")
                        .font(.headline)
                        .foregroundColor(.healixTextPrimary)
                    
                    TextField("Enter weight", text: $weight)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            
            // Blood Type Selection
            VStack(alignment: .leading, spacing: 5) {
                Text("Blood Type (Optional)")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Menu {
                    ForEach(bloodTypeOptions, id: \.self) { option in
                        Button(action: {
                            bloodType = option
                        }) {
                            Text(option)
                        }
                    }
                } label: {
                    HStack {
                        Text(bloodType)
                            .foregroundColor(bloodType == "Select" ? .gray : .healixTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            
            // Allergies Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Allergies (Optional)")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                TextField("Enter allergies, separated by commas", text: $allergies)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Chronic Conditions Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Chronic Conditions (Optional)")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                TextField("Enter chronic conditions, separated by commas", text: $chronicConditions)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Methods
    
    // Validate Account Information
    private func validateAccountInfo() -> Bool {
        // Check if Core Data is initialized
        if !PersistenceController.shared.isStoreLoaded {
            alertTitle = "Database Error"
            alertMessage = "Database is not properly initialized. Please restart the app."
            showAlert = true
            return false
        }
        
        // Verify the User entity exists
        if !PersistenceController.shared.entityExists("User") {
            alertTitle = "Schema Error"
            alertMessage = "Database schema is missing User entity. Please reinstall the app."
            showAlert = true
            return false
        }
        
        // Check if username is empty
        if username.isEmpty {
            alertTitle = "Invalid Username"
            alertMessage = "Username cannot be empty."
            showAlert = true
            return false
        }
        
        // Check if username already exists
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            let count = try viewContext.count(for: request)
            if count > 0 {
                alertTitle = "Username Taken"
                alertMessage = "This username is already taken. Please choose another one."
                showAlert = true
                return false
            }
        } catch {
            print("Error checking username: \(error)")
            alertTitle = "Database Error"
            alertMessage = "Error checking username availability. Please try again."
            showAlert = true
            return false
        }
        
        // Check password
        if password.isEmpty {
            alertTitle = "Invalid Password"
            alertMessage = "Password cannot be empty."
            showAlert = true
            return false
        }
        
        // Check if passwords match
        if password != confirmPassword {
            alertTitle = "Password Mismatch"
            alertMessage = "Passwords do not match."
            showAlert = true
            return false
        }
        
        return true
    }
    
    // Validate Demographic Information
    private func validateDemographicInfo() -> Bool {
        // Validate age
        if age.isEmpty {
            alertTitle = "Invalid Age"
            alertMessage = "Please enter your age."
            showAlert = true
            return false
        }
        
        guard let ageInt = Int(age), ageInt > 0, ageInt < 120 else {
            alertTitle = "Invalid Age"
            alertMessage = "Please enter a valid age."
            showAlert = true
            return false
        }
        
        // Validate gender
        if gender == "Select" {
            alertTitle = "Invalid Gender"
            alertMessage = "Please select your gender."
            showAlert = true
            return false
        }
        
        // Validate height
        if height.isEmpty {
            alertTitle = "Invalid Height"
            alertMessage = "Please enter your height."
            showAlert = true
            return false
        }
        
        guard let heightDouble = Double(height), heightDouble > 0 else {
            alertTitle = "Invalid Height"
            alertMessage = "Please enter a valid height."
            showAlert = true
            return false
        }
        
        // Validate weight
        if weight.isEmpty {
            alertTitle = "Invalid Weight"
            alertMessage = "Please enter your weight."
            showAlert = true
            return false
        }
        
        guard let weightDouble = Double(weight), weightDouble > 0 else {
            alertTitle = "Invalid Weight"
            alertMessage = "Please enter a valid weight."
            showAlert = true
            return false
        }
        
        return true
    }
    
    // Register User
    private func registerUser() {
        // Validate demographic information
        guard validateDemographicInfo() else { return }
        
        // Show loading state
        isRegistering = true
        
        // Get a background context for the operation
        let context = PersistenceController.shared.createBackgroundContext()
        
        // Perform the operation on background thread
        context.perform {
            // Create user
            let user = User(context: context)
            user.id = UUID()
            user.username = self.username
            user.password = self.password
            user.createdAt = Date()
            
            // Create demographic info
            let demographics = DemographicInfo(context: context)
            demographics.id = UUID()
            demographics.age = Int16(self.age) ?? 0
            demographics.gender = self.gender
            demographics.height = Double(self.height) ?? 0.0
            demographics.weight = Double(self.weight) ?? 0.0
            
            // Set optional fields
            if self.bloodType != "Select" {
                demographics.bloodType = self.bloodType
            }
            if !self.allergies.isEmpty {
                demographics.allergies = self.allergies
            }
            if !self.chronicConditions.isEmpty {
                demographics.chronicConditions = self.chronicConditions
            }
            
            // Link user and demographics
            demographics.user = user
            user.demographics = demographics
            
            // Save the context with completion handler
            PersistenceController.shared.saveContext(context) { success, error in
                // Update UI on main thread
                DispatchQueue.main.async {
                    // Hide loading state
                    self.isRegistering = false
                    
                    if success {
                        // Show success alert
                        self.alertTitle = "Registration Successful"
                        self.alertMessage = "Your account has been created successfully. You can now log in."
                        self.navigateToLogin = true
                        self.showAlert = true
                    } else {
                        // Show error alert
                        self.alertTitle = "Registration Failed"
                        self.alertMessage = "An error occurred while creating your account: \(error?.localizedDescription ?? "Unknown error")"
                        self.showAlert = true
                    }
                }
            }
        }
    }
}

// MARK: - ProgressBar
struct ProgressBar: View {
    var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: CGFloat(self.value) * geometry.size.width, height: geometry.size.height)
                    .foregroundColor(.healixBlue)
            }
            .cornerRadius(45.0)
        }
    }
}

// MARK: - Preview
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
