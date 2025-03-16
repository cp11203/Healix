//
//  MainView.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import SwiftUI
import CoreData

struct MainView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTab: Tab = .home
    
    // Current user state
    @State private var currentUser: User? = nil
    @State private var ongoingSymptoms: [Symptom] = []
    @State private var acuteSymptoms: [Symptom] = []
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.healixBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // User Header
                            userHeader
                            
                            // Health Overview Button
                            NavigationLink {
                                HealthOverviewView()
                                    .environment(\.managedObjectContext, viewContext)
                            } label: {
                                healthOverviewButton
                            }
                            
                            // Record Symptoms Button
                            NavigationLink {
                                RecordSymptomsView()
                                    .environment(\.managedObjectContext, viewContext)
                            } label: {
                                recordSymptomsButton
                            }
                            
                            // Ongoing Symptoms Section
                            ongoingSymptomSection
                            
                            // Acute Symptoms Section
                            acuteSymptomSection
                            
                            // Capabilities Section
                            capabilitiesSection
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Healix")
                        .font(.headline)
                        .foregroundColor(.healixDarkBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        logout()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.healixBlue)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                loadUserAndSymptomsData()
            }
        }
    }
    
    // MARK: - Subviews
    
    // User Header
    private var userHeader: some View {
        HStack {
            // User Avatar
            ZStack {
                Circle()
                    .fill(Color.healixLightBlue)
                    .frame(width: 40, height: 40)
                
                Text(currentUser?.username?.prefix(1).uppercased() ?? "U")
                    .font(.headline)
                    .foregroundColor(.healixDarkBlue)
            }
            
            VStack(alignment: .leading) {
                Text(currentUser?.username ?? "User Name")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Text("Your Health, Your Voice")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
    
    // Health Overview Button
    private var healthOverviewButton: some View {
        ZStack {
            Rectangle()
                .fill(Color.healixBlue)
                .cornerRadius(10)
                .frame(height: 70)
            
            HStack {
                Text("Health Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)
        }
    }
    
    // Record Symptoms Button
    private var recordSymptomsButton: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .cornerRadius(10)
                .frame(height: 60)
            
            HStack {
                Text("Record Symptoms")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)
        }
    }
    
    // Ongoing Symptoms Section
    private var ongoingSymptomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ongoing")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Spacer()
                
                NavigationLink {
                    RecordSymptomsView()
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.healixBlue)
                }
            }
            
            if ongoingSymptoms.isEmpty {
                Text("No ongoing symptoms")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(ongoingSymptoms) { symptom in
                            NavigationLink {
                                SymptomDetailView(symptom: symptom)
                                    .environment(\.managedObjectContext, viewContext)
                            } label: {
                                SymptomCard(
                                    symptom: symptom,
                                    isOngoing: true,
                                    deleteSymptom: deleteSymptom
                                )
                                .frame(width: 120, height: 120)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Acute Symptoms Section
    private var acuteSymptomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Acute")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Spacer()
                
                NavigationLink {
                    RecordSymptomsView()
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.healixBlue)
                }
            }
            
            if acuteSymptoms.isEmpty {
                Text("No acute symptoms")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(acuteSymptoms) { symptom in
                        NavigationLink {
                            SymptomDetailView(symptom: symptom)
                                .environment(\.managedObjectContext, viewContext)
                        } label: {
                            SymptomCard(
                                symptom: symptom,
                                isOngoing: false,
                                deleteSymptom: deleteSymptom
                            )
                            .frame(height: 120)
                        }
                    }
                }
            }
        }
    }
    
    // Capabilities Section
    private var capabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Capabilities")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            // Medications
            NavigationLink {
                MedicationsView()
                    .environment(\.managedObjectContext, viewContext)
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.healixLightBlue)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "cross.fill")
                            .foregroundColor(.healixBlue)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Medications")
                            .font(.headline)
                            .foregroundColor(.healixTextPrimary)
                        
                        Text("Prescription/OTC")
                            .font(.subheadline)
                            .foregroundColor(.healixTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // Medical History
            NavigationLink {
                MedicalHistoryView()
                    .environment(\.managedObjectContext, viewContext)
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.healixGreen.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.healixGreen)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Medical History")
                            .font(.headline)
                            .foregroundColor(.healixTextPrimary)
                        
                        Text("Doctors Forms")
                            .font(.subheadline)
                            .foregroundColor(.healixTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Methods
    
    // Load user and symptoms data
    private func loadUserAndSymptomsData() {
        guard let userIdString = UserDefaults.standard.string(forKey: "loggedInUserId"),
              let userId = UUID(uuidString: userIdString) else {
            // Handle case where user is not logged in
            logout()
            return
        }
        
        // Load the current user first
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        userRequest.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(userRequest)
            guard let user = users.first else {
                // User not found, log out
                logout()
                return
            }
            
            currentUser = user
            
            // Now load ongoing symptoms
            let ongoingRequest: NSFetchRequest<Symptom> = Symptom.fetchRequest()
            ongoingRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "user.id == %@", userId as CVarArg),
                NSPredicate(format: "isOngoing == %@", NSNumber(value: true))
            ])
            ongoingRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Symptom.lastUpdated, ascending: false)]
            
            // Load acute symptoms
            let acuteRequest: NSFetchRequest<Symptom> = Symptom.fetchRequest()
            acuteRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "user.id == %@", userId as CVarArg),
                NSPredicate(format: "isOngoing == %@", NSNumber(value: false))
            ])
            acuteRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Symptom.lastUpdated, ascending: false)]
            
            // Execute the fetches
            ongoingSymptoms = try viewContext.fetch(ongoingRequest)
            acuteSymptoms = try viewContext.fetch(acuteRequest)
            
        } catch {
            print("Error fetching user or symptoms: \(error)")
        }
    }
    
    // Delete symptom (changed from moveSymptom)
    private func deleteSymptom(symptom: Symptom) {
        // Delete symptom from Core Data
        viewContext.delete(symptom)
        
        do {
            try viewContext.save()
            
            // Reload symptoms after deletion
            loadUserAndSymptomsData()
        } catch {
            print("Error deleting symptom: \(error)")
        }
    }
    
    // Logout
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "loggedInUserId")
        
        if let window = UIApplication.shared.windows.first {
            let loginView = NavigationStack {
                LoginView()
                    .environment(\.managedObjectContext, viewContext)
            }
            
            window.rootViewController = UIHostingController(rootView: loginView)
            window.makeKeyAndVisible()
        }
    }
}

// MARK: - SymptomCard
struct SymptomCard: View {
    let symptom: Symptom
    let isOngoing: Bool
    let deleteSymptom: (Symptom) -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(symptomColor)
                .cornerRadius(10)
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        deleteSymptom(symptom)
                    }) {
                        Image(systemName: "trash.circle")
                            .foregroundColor(.white.opacity(0.8))
                            .padding(5)
                    }
                    .background(Circle().fill(Color.black.opacity(0.1)))
                }
                
                Spacer()
                
                Text(String(symptom.title?.prefix(1) ?? "").uppercased())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(symptom.title ?? "Illness")
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(8)
        }
    }
    
    // Get color based on symptom
    private var symptomColor: Color {
        // Generate a consistent color based on the symptom title
        guard let title = symptom.title else { return .healixBlue }
        
        let colors: [Color] = [
            .healixRed,
            .healixGreen,
            .healixBlue,
            .healixOrange
        ]
        
        let hash = title.hash & 0x7fffffff
        let index = hash % colors.count
        
        return colors[index]
    }
}

// Tab enum for main navigation
enum Tab {
    case home
    case symptoms
    case medications
    case profile
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
