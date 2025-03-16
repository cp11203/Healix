//
//  MedicalHistoryView.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import SwiftUI
import CoreData

struct MedicalHistoryView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedCategory: HistoryCategory = .symptoms
    @State private var showAddDocumentSheet = false
    
    // User and symptoms state
    @State private var currentUser: User? = nil
    @State private var symptoms: [Symptom] = []
    @State private var medications: [Medication] = []
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Category Selection
            categoryPicker
            
            Divider()
                .padding(.top, 5)
            
            // Content based on selected category
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedCategory {
                    case .symptoms:
                        symptomsHistoryView
                    case .medications:
                        medicationsHistoryView
                    case .doctors:
                        doctorsNotesView
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Medical History")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.healixBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedCategory == .doctors {
                    Button(action: {
                        showAddDocumentSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.healixBlue)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddDocumentSheet) {
            AddDocumentView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            loadUserAndData()
        }
    }
    
    // MARK: - Subviews
    
    // Category Picker
    private var categoryPicker: some View {
        HStack(spacing: 0) {
            ForEach(HistoryCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    VStack(spacing: 8) {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(selectedCategory == category ? .healixBlue : .healixTextSecondary)
                        
                        Rectangle()
                            .fill(selectedCategory == category ? Color.healixBlue : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // Symptoms History View
    private var symptomsHistoryView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Symptom History")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            if symptoms.isEmpty {
                Text("No symptom history available")
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
                        SymptomHistoryItem(symptom: symptom)
                    }
                }
            }
        }
    }
    
    // Medications History View
    private var medicationsHistoryView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Medication History")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            if medications.isEmpty {
                Text("No medication history available")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                if medications.count > 1 {
                    MedicationHistoryChart(medications: medications)
                }
                
                ForEach(medications) { medication in
                    MedicationHistoryItem(medication: medication)
                }
            }
        }
    }
    
    // Doctors Notes View
    private var doctorsNotesView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Doctors Forms & Notes")
                .font(.headline)
                .foregroundColor(.healixTextPrimary)
            
            // Sample doctor's notes
            ForEach(sampleDoctorNotes, id: \.title) { note in
                DoctorNoteItem(note: note)
            }
            
            Text("Upload a document by tapping the + button")
                .font(.subheadline)
                .foregroundColor(.healixTextSecondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Methods
    
    // Load user and related data
    private func loadUserAndData() {
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
                
                // Fetch symptoms
                let symptomRequest: NSFetchRequest<Symptom> = Symptom.fetchRequest()
                symptomRequest.predicate = NSPredicate(format: "user.id == %@", uuid as CVarArg)
                symptomRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Symptom.startDate, ascending: false)]
                symptoms = try viewContext.fetch(symptomRequest)
                
                // Fetch medications
                let medicationRequest: NSFetchRequest<Medication> = Medication.fetchRequest()
                medicationRequest.predicate = NSPredicate(format: "user.id == %@", uuid as CVarArg)
                medicationRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.startDate, ascending: false)]
                medications = try viewContext.fetch(medicationRequest)
            }
        } catch {
            print("Error fetching user or related data: \(error)")
        }
    }
}

// MARK: - Supporting Types

// History Categories
enum HistoryCategory: CaseIterable {
    case symptoms
    case medications
    case doctors
    
    var displayName: String {
        switch self {
        case .symptoms:
            return "Symptoms"
        case .medications:
            return "Medications"
        case .doctors:
            return "Doctors Notes"
        }
    }
}

// Sample Doctor Note
struct DoctorNote {
    let title: String
    let doctorName: String
    let date: Date
    let type: String
    
    static var samples: [DoctorNote] {
        [
            DoctorNote(
                title: "Annual Physical Examination",
                doctorName: "Dr. Sarah Johnson",
                date: Date().addingTimeInterval(-86400 * 120), // 120 days ago
                type: "Physical Exam"
            ),
            DoctorNote(
                title: "Blood Test Results",
                doctorName: "Dr. Michael Chen",
                date: Date().addingTimeInterval(-86400 * 60), // 60 days ago
                type: "Lab Results"
            ),
            DoctorNote(
                title: "Vaccination Record",
                doctorName: "Dr. Emily Williams",
                date: Date().addingTimeInterval(-86400 * 30), // 30 days ago
                type: "Immunization"
            )
        ]
    }
}

// MARK: - Custom Views

// Symptom History Item
struct SymptomHistoryItem: View {
    let symptom: Symptom
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(symptom.title ?? "Unknown Symptom")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Text(symptom.description_field?.prefix(50) ?? "No description")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                    .lineLimit(1)
                
                HStack {
                    Text("Started: \(symptom.startDate.map { dateFormatter.string(from: $0) } ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.healixTextSecondary)
                    
                    if !symptom.isOngoing {
                        Text("Ended: \(symptom.lastUpdated.map { dateFormatter.string(from: $0) } ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.healixTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Status badge
            Text(symptom.isOngoing ? "Ongoing" : "Resolved")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(symptom.isOngoing ? Color.healixBlue : Color.healixGreen)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Medication History Item
struct MedicationHistoryItem: View {
    let medication: Medication
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(medication.name ?? "Unknown Medication")
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Text("\(medication.dosage ?? "No dosage") - \(medication.frequency ?? "No frequency")")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                
                HStack {
                    Text("Started: \(medication.startDate.map { dateFormatter.string(from: $0) } ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.healixTextSecondary)
                    
                    if let endDate = medication.endDate {
                        Text("Ended: \(dateFormatter.string(from: endDate))")
                            .font(.caption)
                            .foregroundColor(.healixTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Status badge
            MedicationStatusBadge(endDate: medication.endDate)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Medication History Chart
struct MedicationHistoryChart: View {
    let medications: [Medication]
    
    private let timelineHeight: CGFloat = 20
    private let timelineStartDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    
    private var sortedMedications: [Medication] {
        medications.sorted { med1, med2 in
            (med1.startDate ?? Date()) < (med2.startDate ?? Date())
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Medication Timeline (Past Year)")
                .font(.subheadline)
                .foregroundColor(.healixTextSecondary)
            
            ZStack(alignment: .leading) {
                // Timeline background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: timelineHeight)
                    .cornerRadius(timelineHeight / 2)
                
                // Month indicators
                ForEach(0..<12) { month in
                    let position = monthPosition(month: month)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 1, height: timelineHeight)
                        .offset(x: position)
                }
                
                // Medication bars
                ForEach(sortedMedications) { medication in
                    medicationBar(for: medication)
                }
            }
            .frame(height: timelineHeight)
            .padding(.vertical, 10)
            
            // Month labels
            HStack {
                ForEach(0..<4) { i in
                    let month = i * 3
                    Text(monthLabel(month: month))
                        .font(.caption2)
                        .foregroundColor(.healixTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Generate a medication bar
    private func medicationBar(for medication: Medication) -> some View {
        let startPosition = datePosition(date: medication.startDate ?? Date())
        let endPosition = datePosition(date: medication.endDate ?? Date())
        let width = max(endPosition - startPosition, 5) // Minimum width for visibility
        
        return Rectangle()
            .fill(medicationColor(for: medication))
            .frame(width: width, height: timelineHeight * 0.8)
            .cornerRadius(3)
            .offset(x: startPosition)
    }
    
    // Get position for a month
    private func monthPosition(month: Int) -> CGFloat {
        let totalWidth = UIScreen.main.bounds.width - 40 // Accounting for padding
        return totalWidth * CGFloat(month) / 12.0
    }
    
    // Get position for a date
    private func datePosition(date: Date) -> CGFloat {
        let totalWidth = UIScreen.main.bounds.width - 40 // Accounting for padding
        let totalDays = Calendar.current.dateComponents([.day], from: timelineStartDate, to: Date()).day ?? 365
        let daysFromStart = Calendar.current.dateComponents([.day], from: timelineStartDate, to: date).day ?? 0
        
        let position = totalWidth * CGFloat(daysFromStart) / CGFloat(totalDays)
        return max(0, min(position, totalWidth))
    }
    
    // Get month label
    private func monthLabel(month: Int) -> String {
        let date = Calendar.current.date(byAdding: .month, value: month, to: timelineStartDate) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    // Get color for medication
    private func medicationColor(for medication: Medication) -> Color {
        guard let name = medication.name else { return .healixBlue }
        
        let hash = name.hash & 0x7fffffff
        let colors: [Color] = [.healixBlue, .healixGreen, .healixRed, .healixOrange]
        let index = hash % colors.count
        
        return colors[index]
    }
}

// Doctor Note Item
struct DoctorNoteItem: View {
    let note: DoctorNote
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.healixTextPrimary)
                
                Text("Dr. \(note.doctorName)")
                    .font(.subheadline)
                    .foregroundColor(.healixTextSecondary)
                
                Text(dateFormatter.string(from: note.date))
                    .font(.caption)
                    .foregroundColor(.healixTextSecondary)
            }
            
            Spacer()
            
            // Document type badge
            Text(note.type)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.healixBlue)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Add Document View
struct AddDocumentView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var title: String = ""
    @State private var doctorName: String = ""
    @State private var date: Date = Date()
    @State private var documentType: String = "Physical Exam"
    @State private var showDocumentPicker = false
    @State private var documentURL: URL?
    @State private var documentName: String = "No document selected"
    
    // Document type options
    private let documentTypes = ["Physical Exam", "Lab Results", "Prescription", "Specialist Referral", "Immunization", "Other"]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Document Form
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Document Title")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            TextField("Enter document title", text: $title)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Doctor Name
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Doctor Name")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            TextField("Enter doctor's name", text: $doctorName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Date
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Date")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Document Type
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Document Type")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            Picker("Document Type", selection: $documentType) {
                                ForEach(documentTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Document Upload
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Upload Document")
                                .font(.headline)
                                .foregroundColor(.healixTextPrimary)
                            
                            Button(action: {
                                showDocumentPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.healixBlue)
                                    
                                    Text(documentName)
                                        .foregroundColor(.healixTextPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "paperclip")
                                        .foregroundColor(.healixBlue)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Document")
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
                        saveDocument()
                    }
                    .disabled(title.isEmpty || doctorName.isEmpty)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(documentURL: $documentURL, documentName: $documentName)
            }
        }
    }
    
    // MARK: - Methods
    
    // Save Document
    private func saveDocument() {
        // In a real app, this would save the document to Core Data
        // For the demo, just dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}

// Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var documentURL: URL?
    @Binding var documentName: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .image])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            parent.documentURL = url
            parent.documentName = url.lastPathComponent
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct MedicalHistoryView_Previews: PreviewProvider {
    static var sampleDoctorNotes: [DoctorNote] {
        DoctorNote.samples
    }
    
    static var previews: some View {
        NavigationView {
            MedicalHistoryView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}

// MARK: - Sample Doctor Notes (for preview)
extension MedicalHistoryView {
    var sampleDoctorNotes: [DoctorNote] {
        DoctorNote.samples
    }
}
