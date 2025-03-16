//
//  HealthOverviewView.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import SwiftUI
import CoreData

struct HealthOverviewView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var selectedTab = 0
    @State private var userId: UUID? = nil
    
    // Optimized fetch of current user
    @State private var currentUser: User? = nil
    
    // Fetch all symptoms for the current user
    @State private var symptomsFetchRequest: FetchRequest<Symptom>?
    @State private var symptoms: [Symptom] = []
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            HStack {
                TabButton(
                    title: "Medical History",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                TabButton(
                    title: "Health Trends",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Divider()
                .padding(.top, 5)
            
            // Tab Content
            if selectedTab == 0 {
                medicalHistoryTab
            } else {
                healthTrendsTab
            }
        }
        .navigationTitle("Health Overview")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.healixBackground)
        .onAppear {
            setupUserAndFetchRequests()
        }
    }
    
    // MARK: - Subviews
    
    // Medical History Tab
    private var medicalHistoryTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic Information
                demographicSection
                
                // Timeline of Symptoms
                symptomTimelineSection
            }
            .padding()
        }
    }
    
    // Health Trends Tab
    private var healthTrendsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Symptom Frequency
                symptomFrequencySection
                
                // Health Metrics
                healthMetricsSection
            }
            .padding()
        }
    }
    
    // Demographic Information
    private var demographicSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            VStack(spacing: 15) {
                demographicRow(title: "Age", value: "\(currentUser?.demographics?.age ?? 0) years")
                demographicRow(title: "Gender", value: currentUser?.demographics?.gender ?? "Not specified")
                demographicRow(title: "Height", value: "\(currentUser?.demographics?.height ?? 0) cm")
                demographicRow(title: "Weight", value: "\(currentUser?.demographics?.weight ?? 0) kg")
                
                if let bloodType = currentUser?.demographics?.bloodType, !bloodType.isEmpty {
                    demographicRow(title: "Blood Type", value: bloodType)
                }
                
                if let allergies = currentUser?.demographics?.allergies, !allergies.isEmpty {
                    demographicRow(title: "Allergies", value: allergies)
                }
                
                if let chronicConditions = currentUser?.demographics?.chronicConditions, !chronicConditions.isEmpty {
                    demographicRow(title: "Chronic Conditions", value: chronicConditions)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Helper for demographic rows
    private func demographicRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.healixTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.healixTextPrimary)
        }
    }
    
    // Symptom Timeline
    private var symptomTimelineSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Symptom Timeline")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            if symptoms.isEmpty {
                Text("No symptoms recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                ForEach(symptoms) { symptom in
                    NavigationLink(destination: SymptomDetailView(symptom: symptom)) {
                        TimelineItem(symptom: symptom)
                    }
                }
            }
        }
    }
    
    // Symptom Frequency Chart
    private var symptomFrequencySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Symptom Frequency")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            if symptoms.isEmpty {
                Text("No data available yet")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // Simple bar chart of symptoms by count
                VStack {
                    ForEach(symptomFrequencyData(), id: \.title) { item in
                        HStack {
                            Text(item.title)
                                .font(.subheadline)
                                .foregroundColor(.healixTextPrimary)
                                .frame(width: 100, alignment: .leading)
                            
                            ProgressBar(value: Double(item.count) / Double(maxSymptomCount()))
                                .frame(height: 20)
                            
                            Text("\(item.count)")
                                .font(.subheadline)
                                .foregroundColor(.healixTextSecondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // Health Metrics Section
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Health Metrics")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            VStack(spacing: 15) {
                // Average symptom duration
                HStack {
                    VStack(alignment: .leading) {
                        Text("Average Symptom Duration")
                            .font(.subheadline)
                            .foregroundColor(.healixTextSecondary)
                        
                        Text("\(Int(averageSymptomDuration())) days")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.healixTextPrimary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.healixLightBlue)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "clock.fill")
                            .foregroundColor(.healixBlue)
                    }
                }
                
                // Number of ongoing vs acute symptoms
                HStack {
                    VStack(alignment: .leading) {
                        Text("Ongoing vs Acute")
                            .font(.subheadline)
                            .foregroundColor(.healixTextSecondary)
                        
                        HStack {
                            Text("\(ongoingSymptomCount())")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.healixBlue)
                            
                            Text("vs")
                                .font(.subheadline)
                                .foregroundColor(.healixTextSecondary)
                            
                            Text("\(acuteSymptomCount())")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.healixRed)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.healixGreen.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(.healixGreen)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Helper Methods
    
    // Setup user and fetch requests
    private func setupUserAndFetchRequests() {
        guard let userIdString = UserDefaults.standard.string(forKey: "loggedInUserId"),
              let uuid = UUID(uuidString: userIdString) else {
            return
        }
        
        userId = uuid
        
        // Fetch the current user first
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        userRequest.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(userRequest)
            if let user = users.first {
                currentUser = user
                
                // Now set up symptom fetch request
                let request = FetchRequest<Symptom>(
                    sortDescriptors: [NSSortDescriptor(keyPath: \Symptom.startDate, ascending: false)],
                    predicate: NSPredicate(format: "user.id == %@", uuid as CVarArg)
                )
                
                symptomsFetchRequest = request
                symptoms = Array(request.wrappedValue)
            }
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    // Calculate symptom frequency data
    private func symptomFrequencyData() -> [(title: String, count: Int)] {
        var frequencyMap: [String: Int] = [:]
        
        for symptom in symptoms {
            if let title = symptom.title {
                frequencyMap[title, default: 0] += 1
            }
        }
        
        return frequencyMap.map { (title: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { (title: $0.title, count: $0.count) }
    }
    
    // Get maximum symptom count for scaling
    private func maxSymptomCount() -> Int {
        let counts = symptomFrequencyData().map { $0.count }
        return counts.max() ?? 1
    }
    
    // Calculate average symptom duration
    private func averageSymptomDuration() -> Double {
        let nonOngoingSymptoms = symptoms.filter { !$0.isOngoing }
        
        guard !nonOngoingSymptoms.isEmpty else { return 0 }
        
        let totalDays = nonOngoingSymptoms.reduce(0) { result, symptom in
            let endDate = symptom.lastUpdated ?? Date()
            let startDate = symptom.startDate ?? endDate
            let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            return result + days
        }
        
        return Double(totalDays) / Double(nonOngoingSymptoms.count)
    }
    
    // Count ongoing symptoms
    private func ongoingSymptomCount() -> Int {
        return symptoms.filter { $0.isOngoing }.count
    }
    
    // Count acute symptoms
    private func acuteSymptomCount() -> Int {
        return symptoms.filter { !$0.isOngoing }.count
    }
}

// MARK: - TimelineItem
struct TimelineItem: View {
    let symptom: Symptom
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Timeline dot and line
            VStack {
                Circle()
                    .fill(symptom.isOngoing ? Color.healixBlue : Color.healixGreen)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 20)
            
            // Symptom information
            VStack(alignment: .leading, spacing: 5) {
                Text(symptom.title ?? "Unknown Symptom")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Text(symptom.description_field ?? "No description")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .lineLimit(2)
                
                Text("Started: \(symptom.startDate.map { dateFormatter.string(from: $0) } ?? "Unknown date")")
                    .font(.caption)
                    .foregroundColor(.healixTextSecondary)
                
                if !symptom.isOngoing {
                    Text("Ended: \(symptom.lastUpdated.map { dateFormatter.string(from: $0) } ?? "Unknown date")")
                        .font(.caption)
                        .foregroundColor(.healixTextSecondary)
                }
                
                // Status pill
                HStack {
                    Text(symptom.isOngoing ? "Ongoing" : "Resolved")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(symptom.isOngoing ? Color.healixBlue : Color.healixGreen)
                        .cornerRadius(10)
                    
                    Spacer()
                }
                .padding(.top, 5)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Preview
struct HealthOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        HealthOverviewView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
