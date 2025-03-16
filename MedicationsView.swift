//
//  MedicationsView.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import SwiftUI
import CoreData

struct MedicationsView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showAddMedicationSheet = false
    @State private var currentUser: User? = nil
    @State private var medications: [Medication] = []
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Medications
                currentMedicationsSection
                
                // Past Medications
                pastMedicationsSection
            }
            .padding()
        }
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.healixBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddMedicationSheet = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.healixBlue)
                }
            }
        }
        .sheet(isPresented: $showAddMedicationSheet) {
            AddMedicationView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            fetchUserAndMedications()
        }
    }
    
    // MARK: - Subviews
    
    // Current Medications Section
    private var currentMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Current Medications")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            let currentMeds = medications.filter { medication in
                if let endDate = medication.endDate {
                    return endDate > Date()
                }
                return true // No end date means current
            }
            
            if currentMeds.isEmpty {
                Text("No current medications")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                ForEach(currentMeds) { medication in
                    MedicationCard(medication: medication)
                }
            }
        }
    }
    
    // Past Medications Section
    private var pastMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Past Medications")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            let pastMeds = medications.filter { medication in
                if let endDate = medication.endDate {
                    return endDate <= Date()
                }
                return false
            }
            
            if pastMeds.isEmpty {
                Text("No past medications")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                ForEach(pastMeds) { medication in
                    MedicationCard(medication: medication)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    // Fetch user and medications
    private func fetchUserAndMedications() {
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId"),
              let uuid = UUID(uuidString: userId) else {
            return
        }
        
        // Fetch user
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        userRequest.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(userRequest)
            if let user = users.first {
                currentUser = user
                
                // Fetch medications
                let medicationRequest: NSFetchRequest<Medication> = Medication.fetchRequest()
                medicationRequest.predicate = NSPredicate(format: "user.id == %@", uuid as CVarArg)
                medicationRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.startDate, ascending: false)]
                
                medications = try viewContext.fetch(medicationRequest)
            }
        } catch {
            print("Error fetching user or medications: \(error)")
        }
    }
}

// MARK: - MedicationCard
struct MedicationCard: View {
    let medication: Medication
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(medication.name ?? "Unknown Medication")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Spacer()
                
                MedicationStatusBadge(endDate: medication.endDate)
            }
            
            Divider()
            
            // Dosage & Frequency
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Dosage")
                        .font(.caption)
                        .foregroundColor(.healixTextSecondary)
                    
                    Text(medication.dosage ?? "Not specified")
                        .font(.subheadline)
                        .foregroundColor(.healixTextPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Frequency")
                        .font(.caption)
                        .foregroundColor(.healixTextSecondary)
                    
                    Text(medication.frequency ?? "Not specified")
                        .font(.subheadline)
                        .foregroundColor(.healixTextPrimary)
                }
            }
            
            // Dates
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.healixTextSecondary)
                    
                    Text(medication.startDate.map { dateFormatter.string(from: $0) } ?? "Unknown")
                        .font(.subheadline)
                        .foregroundColor(.healixTextPrimary)
                }
                
                Spacer()
                
                if let endDate = medication.endDate {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundColor(.healixTextSecondary)
                        
                        Text(dateFormatter.string(from: endDate))
                            .font(.subheadline)
                            .foregroundColor(.healixTextPrimary)
                    }
                }
            }
            
            // Notes
            if let notes = medication.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.healixTextSecondary)
                    
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.healixTextPrimary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - MedicationStatusBadge
struct MedicationStatusBadge: View {
    let endDate: Date?
    
    var isCurrent: Bool {
        guard let endDate = endDate else { return true }
        return endDate > Date()
    }
    
    var body: some View {
        Text(isCurrent ? "Current" : "Past")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isCurrent ? Color.healixGreen : Color.healixTextSecondary)
            .cornerRadius(8)
    }
}

// MARK: - AddMedicationView
struct AddMedicationView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var frequency: String = ""
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date().addingTimeInterval(86400 * 30) // 30 days from now
    @State private var notes: String = ""
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var currentUser: User? = nil
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Medication Form
                    VStack(spacing: 20) {
                        // Name
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Medication Name")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            TextField("Enter medication name", text: $name)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Dosage
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Dosage")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            TextField("e.g., 500mg", text: $dosage)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Frequency
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Frequency")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            TextField("e.g., Twice daily", text: $frequency)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Start Date
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Start Date")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // End Date Toggle
                        Toggle("Has End Date", isOn: $hasEndDate)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // End Date
                        if hasEndDate {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("End Date")
                                    .font(.headline)
                                    .foregroundColor(.healixTextPrimary)
                                
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.healixBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedication()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                fetchCurrentUser()
            }
        }
    }
    
    // MARK: - Methods
    
    // Fetch current user
    private func fetchCurrentUser() {
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId"),
              let uuid = UUID(uuidString: userId) else {
            return
        }
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        request.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(request)
            currentUser = users.first
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    // Save Medication
    private func saveMedication() {
        // Validate input
        if name.isEmpty {
            alertMessage = "Please enter a medication name."
            showAlert = true
            return
        }
        
        guard let user = currentUser else {
            alertMessage = "User information not found."
            showAlert = true
            return
        }
        
        // Create medication
        let medication = Medication.createMedication(
            name: name,
            dosage: dosage,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            notes: notes.isEmpty ? nil : notes,
            user: user,
            in: viewContext
        )
        
        // Save context
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to save medication. Please try again."
            showAlert = true
            print("Error saving medication: \(error)")
        }
    }
}

// MARK: - Preview
struct MedicationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MedicationsView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
