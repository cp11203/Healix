//
//  SymptomDetailView.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//
import SwiftUI
import CoreData
import Charts

struct SymptomDetailView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    let symptom: Symptom
    @State private var selectedTab = 0
    @State private var showUpdateSheet = false
    @State private var navigateToUpdateSymptom = false
    @State private var showDeleteConfirmation = false
    
    // Fetch reports for the symptom
    @FetchRequest private var reports: FetchedResults<SymptomReport>
    
    // State for AI generated insights
    @State private var patientProfile: [String: Any] = [:]
    @State private var aiInsights: String = ""
    @State private var trendData: [TrendPoint] = []
    @State private var isLoading: Bool = false
    
    // Initialize with custom fetch request
    init(symptom: Symptom) {
        self.symptom = symptom
        
        // Create a fetch request for the symptom's reports
        let request: NSFetchRequest<SymptomReport> = SymptomReport.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SymptomReport.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "symptom == %@", symptom)
        
        _reports = FetchRequest(fetchRequest: request)
    }
    
    // Format dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            HStack {
                TabButton(
                    title: "Report",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                TabButton(
                    title: "Trends",
                    isSelected: selectedTab == 1,
                    action: {
                        selectedTab = 1
                        if trendData.isEmpty {
                            generateTrendData()
                        }
                    }
                )
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Divider()
                .padding(.top, 5)
            
            // Tab Content
            if selectedTab == 0 {
                reportTab
            } else {
                trendsTab
            }
        }
        .navigationTitle(symptom.title ?? "Symptom Detail")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.healixBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showUpdateSheet = true
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.healixBlue)
                }
            }
        }
        .sheet(isPresented: $showUpdateSheet) {
            updateOptionsSheet
        }
        .navigationDestination(isPresented: $navigateToUpdateSymptom) {
            RecordSymptomsView(symptomToUpdate: symptom)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Symptom"),
                message: Text("Are you sure you want to delete this symptom? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteSymptom()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            loadPatientProfile()
            generateAIInsights()
            generateTrendData()
        }
    }
    
    // MARK: - Subviews
    
    // Report Tab
    private var reportTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic Information
                basicInfoSection
                
                // Reports
                reportsSection
            }
            .padding()
        }
    }
    
    // Trends Tab
    private var trendsTab: some View {
        ScrollView {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Analyzing your symptom data...")
                        .padding()
                    Spacer()
                }
                .frame(height: 300)
            } else {
                VStack(spacing: 20) {
                    // AI Insights
                    insightsSection
                    
                    // Symptom Intensity Chart
                    intensitySection
                    
                    // Symptom Duration Chart
                    durationSection
                }
                .padding()
            }
        }
    }
    
    // Basic Information Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            VStack(spacing: 15) {
                infoRow(title: "Status", value: symptom.isOngoing ? "Ongoing" : "Resolved")
                
                infoRow(
                    title: "Started",
                    value: symptom.startDate.map { dateFormatter.string(from: $0) } ?? "Unknown"
                )
                
                if !symptom.isOngoing {
                    infoRow(
                        title: "Ended",
                        value: symptom.lastUpdated.map { dateFormatter.string(from: $0) } ?? "Unknown"
                    )
                }
                
                infoRow(
                    title: "Last Updated",
                    value: symptom.lastUpdated.map { dateFormatter.string(from: $0) } ?? "Unknown"
                )
                
                if symptom.isOngoing {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete Symptom")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.healixRed)
                            .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
                } else {
                    // Added delete button for acute symptoms as well
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete Symptom")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.healixRed)
                            .cornerRadius(20)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Helper for info rows
    private func infoRow(title: String, value: String) -> some View {
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
    
    // Reports Section
    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Reports")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            if reports.isEmpty {
                Text("No reports available")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                ForEach(reports) { report in
                    reportCard(report: report)
                }
            }
        }
    }
    
    // Report Card
    private func reportCard(report: SymptomReport) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Report Generated \(report.createdAt.map { dateFormatter.string(from: $0) } ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.healixTextSecondary)
                
                Spacer()
                
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.healixBlue)
            }
            
            Divider()
            
            // Scientific Description
            VStack(alignment: .leading, spacing: 5) {
                Text("Clinical Assessment")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Text(report.scientificDescription ?? "No clinical assessment available")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
            }
            .padding(.bottom, 10)
            
            // General Description
            VStack(alignment: .leading, spacing: 5) {
                Text("General Description")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Text(report.generalDescription ?? "No general description available")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
            }
            .padding(.bottom, 10)
            
            // Recommendations
            if let recommendations = report.recommendations, !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Recommendations")
                        .font(.headline)
                        .foregroundColor(.healixTextPrimary)
                    
                    Text(recommendations)
                        .font(.subheadline)
                        .foregroundColor(.healixTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // AI Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("AI Health Insights")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.healixOrange)
                        .font(.title2)
                    
                    Text(aiInsights)
                        .font(.subheadline)
                        .foregroundColor(.healixTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                Text("These insights are based on the information you've provided and general medical knowledge. Always consult with a healthcare professional for medical advice.")
                    .font(.caption)
                    .foregroundColor(.healixTextSecondary)
                    .italic()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Intensity Section with chart
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Symptom Intensity")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            VStack(alignment: .leading, spacing: 10) {
                if trendData.isEmpty {
                    Text("Not enough data to display trends")
                        .font(.subheadline)
                        .foregroundColor(.healixTextSecondary)
                        .padding()
                } else {
                    // Modern SwiftUI Chart
                    Chart {
                        ForEach(trendData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Intensity", point.intensity)
                            )
                            .foregroundStyle(Color.healixBlue)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Intensity", point.intensity)
                            )
                            .foregroundStyle(Color.healixBlue)
                        }
                    }
                    .frame(height: 200)
                    .padding(.top)
                    
                    // Legend
                    HStack(spacing: 15) {
                        Text("Intensity Scale:")
                            .font(.caption)
                            .foregroundColor(.healixTextSecondary)
                        
                        legendItem(color: .green, text: "Mild (1-3)")
                        legendItem(color: .yellow, text: "Moderate (4-6)")
                        legendItem(color: .orange, text: "Severe (7-8)")
                        legendItem(color: .red, text: "Very Severe (9-10)")
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Symptom Duration & Timeline")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            VStack(alignment: .leading, spacing: 15) {
                // Duration calculation
                let duration = calculateDuration()
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Total Duration")
                            .font(.subheadline)
                            .foregroundColor(.healixTextSecondary)
                        
                        Text("\(duration) days")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.healixBlue)
                    }
                    
                    Spacer()
                    
                    if let averageDuration = calculateAverageDuration() {
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("Typical Duration")
                                .font(.subheadline)
                                .foregroundColor(.healixTextSecondary)
                            
                            Text("\(Int(averageDuration)) days")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(duration > Int(averageDuration) ? .healixRed : .healixGreen)
                        }
                    }
                }
                
                // Timeline visualization for multiple reports
                if reports.count > 1 {
                    Divider()
                    
                    Text("Report Timeline")
                        .font(.subheadline)
                        .foregroundColor(.healixTextSecondary)
                    
                    // Timeline visualization
                    timelineVisualization
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Timeline visualization
    private var timelineVisualization: some View {
        let sortedReports = reports.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 40) {
                ForEach(0..<sortedReports.count, id: \.self) { index in
                    let report = sortedReports[index]
                    VStack(spacing: 5) {
                        // Circle with number
                        ZStack {
                            Circle()
                                .fill(Color.healixBlue)
                                .frame(width: 30, height: 30)
                            
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        // Connecting line if not the last item
                        if index < sortedReports.count - 1 {
                            Rectangle()
                                .fill(Color.healixBlue)
                                .frame(width: 2, height: 30)
                        }
                        
                        // Date
                        Text(shortDateFormatter.string(from: report.createdAt ?? Date()))
                            .font(.caption)
                            .foregroundColor(.healixTextSecondary)
                    }
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 20)
        }
    }
    
    // Legend item for intensity chart
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.healixTextSecondary)
        }
    }
    
    // Update Options Sheet
    private var updateOptionsSheet: some View {
        VStack(spacing: 20) {
            Text("Update Options")
                .font(.headline)
                .padding(.top)
            
            Button(action: {
                showUpdateSheet = false
                navigateToUpdateSymptom = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.healixBlue)
                    
                    Text("Update Symptom Information")
                        .foregroundColor(.healixTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: {
                showUpdateSheet = false
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.healixRed)
                    
                    Text("Delete Symptom")
                        .foregroundColor(.healixRed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: {
                showUpdateSheet = false
            }) {
                Text("Cancel")
                    .foregroundColor(.healixTextSecondary)
                    .padding()
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    // Load patient profile for AI context
    private func loadPatientProfile() {
        if let user = symptom.user {
            patientProfile["username"] = user.username
            patientProfile["age"] = user.demographics?.age
            patientProfile["gender"] = user.demographics?.gender
            patientProfile["allergies"] = user.demographics?.allergies
            patientProfile["chronicConditions"] = user.demographics?.chronicConditions
            
            // Load medications for context
            let medicationRequest: NSFetchRequest<Medication> = Medication.fetchRequest()
            medicationRequest.predicate = NSPredicate(format: "user.id == %@", user.id! as CVarArg)
            
            do {
                let medications = try viewContext.fetch(medicationRequest)
                let medicationNames = medications.compactMap { $0.name }
                patientProfile["medications"] = medicationNames
            } catch {
                print("Error fetching medications: \(error)")
            }
        }
    }
    
    // Generate AI Insights
    private func generateAIInsights() {
        isLoading = true
        
        // Check if we can use the OpenAI service
        if let medications = patientProfile["medications"] as? [String] {
            // Gather info about symptom
            let symptomName = symptom.title ?? "this symptom"
            let duration = calculateDuration()
            let isOngoing = symptom.isOngoing
            
            // Get all symptoms from this user for context
            var allSymptoms: [String] = []
            var symptomDurations: [Int] = []
            
            if let userId = symptom.user?.id {
                let symptomsRequest: NSFetchRequest<Symptom> = Symptom.fetchRequest()
                symptomsRequest.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)
                
                do {
                    let userSymptoms = try viewContext.fetch(symptomsRequest)
                    allSymptoms = userSymptoms.compactMap { $0.title }
                    
                    // Calculate durations for each symptom
                    symptomDurations = userSymptoms.map { symptom in
                        let endDate = symptom.isOngoing ? Date() : (symptom.lastUpdated ?? Date())
                        let startDate = symptom.startDate ?? endDate
                        let components = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
                        return max(components.day ?? 0, 1)
                    }
                } catch {
                    print("Error fetching all user symptoms: \(error)")
                }
            }
            
            // Use the OpenAI service to generate insights
            OpenAIService.shared.generateHealthInsights(
                symptoms: allSymptoms,
                symptomDurations: symptomDurations,
                patientProfile: patientProfile,
                medications: medications
            ) { result in
                switch result {
                case .success(let insights):
                    self.aiInsights = insights
                case .failure(let error):
                    print("Error generating AI insights: \(error)")
                    // Fallback to static insights if API fails
                    self.generateStaticInsights()
                }
                self.isLoading = false
            }
        } else {
            // Fallback to static insights
            generateStaticInsights()
            isLoading = false
        }
    }
    
    // Generate static insights as a fallback
    private func generateStaticInsights() {
        let chronicConditions = self.patientProfile["chronicConditions"] as? String
        let medications = self.patientProfile["medications"] as? [String] ?? []
        
        // Gather info about symptom
        let symptomName = self.symptom.title ?? "this symptom"
        let duration = self.calculateDuration()
        let isOngoing = self.symptom.isOngoing
        
        // Build personalized insights
        var insights = "Based on your reported history of \(symptomName.lowercased()), "
        
        // Duration-based insights
        if duration > 14 {
            insights += "the extended duration of \(duration) days is noteworthy. Persistent symptoms often warrant closer monitoring. "
        } else {
            insights += "the current duration of \(duration) days is within typical ranges for similar conditions. "
        }
        
        // Pattern insights (using our trend data)
        if !self.trendData.isEmpty {
            let intensityPattern = self.analyzeIntensityPattern()
            insights += intensityPattern
        }
        
        // Medical context
        if let conditions = chronicConditions, !conditions.isEmpty {
            insights += "Given your history of \(conditions), it's important to monitor how this symptom might interact with your existing conditions. "
        }
        
        if !medications.isEmpty {
            insights += "Your current medications may be relevant to consider in the context of these symptoms. "
        }
        
        // Recommendation
        insights += isOngoing ?
            "Consider discussing this persistent symptom with your healthcare provider at your next appointment." :
            "Since this symptom is marked as resolved, consider documenting any factors that contributed to its resolution for future reference."
        
        self.aiInsights = insights
    }
    
    // Analyze intensity pattern from trend data
    private func analyzeIntensityPattern() -> String {
        guard trendData.count > 1 else { return "" }
        
        // Find the trend direction
        let first = trendData.first!.intensity
        let last = trendData.last!.intensity
        let difference = last - first
        
        if difference > 1 {
            return "The data shows an increasing trend in symptom intensity, which might indicate progression. "
        } else if difference < -1 {
            return "The symptom appears to be improving over time as indicated by the decreasing intensity. "
        } else {
            return "The intensity has remained relatively stable over the observed period. "
        }
    }
    
    // Generate trend data for charts
    private func generateTrendData() {
        var data: [TrendPoint] = []
        
        // Convert report data to trend points
        if reports.count > 0 {
            let sortedReports = reports.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
            
            // Create trend points from reports with simulated intensity values
            for (index, report) in sortedReports.enumerated() {
                guard let date = report.createdAt else { continue }
                
                // Generate an intensity value based on scientific description
                // In real app, this would use NLP to extract severity indicators
                let description = report.scientificDescription ?? ""
                var intensity: Double = 5.0 // Default moderate
                
                if description.lowercased().contains("severe") {
                    intensity = Double.random(in: 7...9)
                } else if description.lowercased().contains("mild") {
                    intensity = Double.random(in: 2...4)
                } else if description.lowercased().contains("moderate") {
                    intensity = Double.random(in: 4...7)
                } else {
                    // Simulate a pattern based on report index
                    if index == 0 {
                        intensity = Double.random(in: 6...8) // Start higher
                    } else {
                        // Either improve or worsen from previous
                        let previousIntensity = data.last?.intensity ?? 5.0
                        let direction = Bool.random() ? 1.0 : -1.0
                        intensity = max(1, min(10, previousIntensity + direction * Double.random(in: 0.5...1.5)))
                    }
                }
                
                data.append(TrendPoint(id: index, date: date, intensity: intensity))
            }
            
            // If only one report, add a second point
            if data.count == 1 {
                let newDate = Calendar.current.date(byAdding: .day, value: -3, to: data[0].date) ?? Date()
                data.insert(TrendPoint(id: 1, date: newDate, intensity: Double.random(in: 4...8)), at: 0)
            }
        } else {
            // Generate example data if no reports
            let today = Date()
            data = [
                TrendPoint(id: 0, date: Calendar.current.date(byAdding: .day, value: -14, to: today)!, intensity: 7.5),
                TrendPoint(id: 1, date: Calendar.current.date(byAdding: .day, value: -10, to: today)!, intensity: 6.8),
                TrendPoint(id: 2, date: Calendar.current.date(byAdding: .day, value: -7, to: today)!, intensity: 5.2),
                TrendPoint(id: 3, date: Calendar.current.date(byAdding: .day, value: -3, to: today)!, intensity: 4.5),
                TrendPoint(id: 4, date: today, intensity: 3.8)
            ]
        }
        
        self.trendData = data.sorted { $0.date < $1.date }
    }
    
    // Calculate symptom duration
    private func calculateDuration() -> Int {
        let endDate = symptom.isOngoing ? Date() : (symptom.lastUpdated ?? Date())
        let startDate = symptom.startDate ?? endDate
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        
        return max(components.day ?? 0, 1) // Minimum 1 day
    }
    
    // Calculate average duration for this type of symptom
    private func calculateAverageDuration() -> Double? {
        // In a real app, this would query similar symptoms or medical data
        // For the demo, provide a simulated average
        
        // Map common symptom keywords to typical durations
        let symptomName = symptom.title?.lowercased() ?? ""
        
        if symptomName.contains("cold") || symptomName.contains("flu") {
            return 7.0
        } else if symptomName.contains("headache") || symptomName.contains("migraine") {
            return 2.0
        } else if symptomName.contains("fever") {
            return 3.0
        } else if symptomName.contains("cough") {
            return 10.0
        } else if symptomName.contains("pain") {
            return 5.0
        } else {
            return 7.0 // Default average
        }
    }
    
    // Delete symptom (changed from markAsResolved)
    private func deleteSymptom() {
        // Delete the symptom record permanently
        viewContext.delete(symptom)
        
        // Also delete associated reports to avoid orphaned data
        for report in reports {
            viewContext.delete(report)
        }
        
        do {
            try viewContext.save()
            // Return to main view after deleting
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error deleting symptom: \(error)")
        }
    }
}

// MARK: - TrendPoint for Charts
struct TrendPoint: Identifiable {
    let id: Int
    let date: Date
    let intensity: Double
}

// MARK: - Preview
struct SymptomDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let symptom = Symptom.createSymptom(
            title: "Headache",
            description: "Persistent headache with pressure behind eyes",
            isOngoing: true,
            startDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            user: User.createUser(username: "preview", password: "password", in: context),
            in: context
        )
        
        _ = SymptomReport.createReport(
            scientificDescription: "Patient presents with symptoms consistent with tension headache.",
            generalDescription: "You're experiencing headaches that seem to be related to stress.",
            recommendations: "Rest, hydration, and over-the-counter pain relievers may help.",
            symptom: symptom,
            in: context
        )
        
        return NavigationStack {
            SymptomDetailView(symptom: symptom)
                .environment(\.managedObjectContext, context)
        }
    }
}
