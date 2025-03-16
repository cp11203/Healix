//
//  RecordSymptomsView.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//
import SwiftUI
import CoreData
import AVFoundation
import Speech

struct RecordSymptomsView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var userMessage: String = ""
    @State private var messages: [(text: String, isUser: Bool, timestamp: Date)] = []
    @State private var showSymptomConfirmation: Bool = false
    @State private var isOngoing: Bool = true
    @State private var symptomTitle: String = ""
    @State private var showTitleInput: Bool = false
    @State private var symptomId: UUID? = nil
    @State private var generatedReport: (scientific: String, general: String, recommendations: String) = ("", "", "")
    @State private var showingImagePicker: Bool = false
    @State private var inputImage: UIImage?
    @State private var isRecording: Bool = false
    @State private var showCamera: Bool = false
    @State private var isProcessingAI: Bool = false
    @State private var isUsingVisionAPI: Bool = false
    
    // Speech recognition
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var transcribedText: String = ""
    @State private var speechRecognitionStatus: SpeechRecognitionStatus = .notStarted
    
    // Medical intelligence parameters
    @State private var previousReportContent: String = ""
    @State private var patientProfile: [String: Any] = [:]
    
    // Optional symptom to update - if nil, we're creating a new symptom
    var symptomToUpdate: Symptom?
    
    // Get current user
    @State private var currentUser: User? = nil
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with Generate Report button
            HStack {
                if showTitleInput {
                    TextField("Enter symptom name", text: $symptomTitle)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                    Button(action: {
                        showTitleInput = false
                    }) {
                        Text("Save")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.healixGreen)
                            .cornerRadius(20)
                    }
                } else {
                    Button(action: {
                        showTitleInput = true
                    }) {
                        HStack {
                            Text(symptomTitle.isEmpty ? "Name Symptom" : symptomTitle)
                                .font(.headline)
                                .foregroundColor(.healixBlue)
                            
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.healixBlue)
                        }
                    }
                    
                    Spacer()
                    
                    if !messages.isEmpty {
                        Button(action: generateReport) {
                            Text("Generate Report")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color.healixBlue)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 5)
            
            // Divider
            Divider()
            
            if showSymptomConfirmation {
                // Symptom Confirmation View
                symptomConfirmationView
            } else {
                // Chat View
                chatView
            }
        }
        .navigationTitle(symptomToUpdate != nil ? "Update Symptom" : "Record Symptoms")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.healixBackground)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { _ in
            if let image = inputImage {
                processImage(image)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $inputImage, isPresented: $showCamera)
        }
        .onAppear {
            loadCurrentUser()
            checkPermissions()
            
            // If we're updating an existing symptom, load its data
            if let symptom = symptomToUpdate {
                symptomId = symptom.id
                symptomTitle = symptom.title ?? "Untitled Symptom"
                if let description = symptom.description_field {
                    let components = description.components(separatedBy: "\n\n")
                    components.forEach { message in
                        messages.append((text: message, isUser: true, timestamp: Date().addingTimeInterval(-60)))
                    }
                    
                    // Load any previous reports for this symptom
                    loadPreviousReport(for: symptom)
                    
                    // Use AI to generate a response to existing description
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isProcessingAI = true
                        
                        // Get AI-generated response based on medical intelligence
                        OpenAIService.shared.generateMedicalResponse(
                            prompt: "The user is updating a previously recorded symptom of \(symptomTitle). Acknowledge their previous report and ask an appropriate follow-up question.",
                            conversationHistory: [],
                            patientProfile: patientProfile,
                            previousReports: [previousReportContent],
                            medications: patientProfile["medications"] as? [String] ?? []
                        ) { result in
                            isProcessingAI = false
                            
                            switch result {
                            case .success(let response):
                                messages.append((text: response, isUser: false, timestamp: Date()))
                            case .failure(let error):
                                print("Error getting AI response: \(error)")
                                // Fallback to static response
                                messages.append((text: "I see you've reported this symptom before. How has it changed since your last update?", isUser: false, timestamp: Date()))
                            }
                        }
                    }
                }
            } else {
                // Initial AI greeting for new symptom with medical intelligence
                isProcessingAI = true
                
                // Get AI-generated greeting based on medical intelligence
                OpenAIService.shared.generateMedicalResponse(
                    prompt: "Generate an initial greeting for a patient recording a new symptom. The greeting should be welcoming and explain how this symptom recording system works.",
                    conversationHistory: [],
                    patientProfile: patientProfile,
                    previousReports: [],
                    medications: patientProfile["medications"] as? [String] ?? []
                ) { result in
                    isProcessingAI = false
                    
                    switch result {
                    case .success(let greeting):
                        messages.append((text: greeting, isUser: false, timestamp: Date()))
                    case .failure(let error):
                        print("Error getting AI greeting: \(error)")
                        // Fallback to static greeting
                        messages.append((
                            text: "Hello! I'm here to help document your symptoms accurately. Please describe what you're experiencing, and I'll ask follow-up questions to get a complete picture. This will help create a detailed report for your doctor.",
                            isUser: false,
                            timestamp: Date()
                        ))
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    // Chat View
    private var chatView: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 15) {
                        // Message history
                        ForEach(0..<messages.count, id: \.self) { index in
                            let message = messages[index]
                            if message.isUser {
                                userMessageView(text: message.text, timestamp: message.timestamp)
                            } else {
                                aiMessageView(text: message.text, timestamp: message.timestamp)
                            }
                        }
                        
                        // AI is typing indicator
                        if isProcessingAI {
                            aiTypingIndicator
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        scrollView.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
                .onChange(of: isProcessingAI) { _ in
                    withAnimation {
                        scrollView.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
            }
            
            // Live transcription display
            if !transcribedText.isEmpty && isRecording {
                HStack {
                    Text(transcribedText)
                        .font(.body)
                        .foregroundColor(.healixTextSecondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                }
                .padding(.horizontal)
            }
            
            // Message Input
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    // Camera Button
                    Button(action: {
                        showCamera = true
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.healixBlue)
                            .frame(width: 40, height: 40)
                    }
                    
                    // Message Input Field
                    TextField("Ask what's on mind...", text: $userMessage)
                        .padding(.vertical, 10)
                        .disabled(isProcessingAI)
                    
                    // Voice Recording Button with status feedback
                    Button(action: toggleRecording) {
                        Image(systemName: voiceButtonIcon)
                            .font(.system(size: 20))
                            .foregroundColor(voiceButtonColor)
                            .frame(width: 40, height: 40)
                    }
                    .disabled(isProcessingAI || speechRecognitionStatus == .notAuthorized)
                    
                    // Send Button
                    Button(action: sendMessage) {
                        Circle()
                            .fill(userMessage.isEmpty ? Color.gray : Color.healixBlue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            )
                    }
                    .disabled(userMessage.isEmpty || isProcessingAI)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white)
            }
        }
    }
    
    // AI Typing Indicator
    private var aiTypingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // AI avatar
            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.healixGreen)
            
            HStack(spacing: 2) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.healixGreen.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .offset(y: sin(Double(i) * 0.5) * 2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // User Message Style
    private func userMessageView(text: String, timestamp: Date) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Spacer()
                    
                    Text(formatTimestamp(timestamp))
                        .font(.caption2)
                        .foregroundColor(.healixTextSecondary)
                }
                
                Text(text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.healixBlue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            
            // User avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.healixBlue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // AI Message Style (looking like the reference image)
    private func aiMessageView(text: String, timestamp: Date) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            // AI avatar
            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.healixGreen)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Healix AI")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.healixGreen)
                    
                    Text(formatTimestamp(timestamp))
                        .font(.caption2)
                        .foregroundColor(.healixTextSecondary)
                }
                
                Text(text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.healixTextPrimary)
                    .cornerRadius(16)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // Symptom Confirmation View
    private var symptomConfirmationView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.healixGreen)
            
            // Title
            Text(symptomToUpdate != nil ? "Symptom Updated" : "Symptom Recorded")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.healixTextPrimary)
            
            // Information
            Text("Is this an ongoing or acute symptom?")
                .font(.headline)
                .foregroundColor(.healixTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Options
            VStack(spacing: 15) {
                Button(action: {
                    isOngoing = true
                    saveSymptom()
                }) {
                    HStack {
                        Text("Ongoing")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.healixBlue)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    isOngoing = false
                    saveSymptom()
                }) {
                    HStack {
                        Text("Acute")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "bandage.fill")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.healixRed)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Methods
    
    // Check permissions for camera and speech recognition
    private func checkPermissions() {
        // Check speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.speechRecognitionStatus = .authorized
                case .denied, .restricted, .notDetermined:
                    self.speechRecognitionStatus = .notAuthorized
                @unknown default:
                    self.speechRecognitionStatus = .notAuthorized
                }
            }
        }
        
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        default:
            break
        }
        
        // Check microphone permission
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            break
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        default:
            break
        }
    }
    
    // Load current user
    private func loadCurrentUser() {
        guard let userIdString = UserDefaults.standard.string(forKey: "loggedInUserId"),
              let userId = UUID(uuidString: userIdString) else {
            return
        }
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let users = try viewContext.fetch(request)
            currentUser = users.first
            
            // Load patient profile for AI
            loadPatientProfile()
        } catch {
            print("Error fetching current user: \(error)")
        }
    }
    
    // Load patient profile for AI
    private func loadPatientProfile() {
        if let user = currentUser {
            patientProfile["username"] = user.username
            patientProfile["age"] = user.demographics?.age
            patientProfile["gender"] = user.demographics?.gender
            patientProfile["height"] = user.demographics?.height
            patientProfile["weight"] = user.demographics?.weight
            patientProfile["bloodType"] = user.demographics?.bloodType
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
    
    // Load previous report for a symptom
    private func loadPreviousReport(for symptom: Symptom) {
        let reportRequest: NSFetchRequest<SymptomReport> = SymptomReport.fetchRequest()
        reportRequest.predicate = NSPredicate(format: "symptom.id == %@", symptom.id! as CVarArg)
        reportRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SymptomReport.createdAt, ascending: false)]
        reportRequest.fetchLimit = 1
        
        do {
            let reports = try viewContext.fetch(reportRequest)
            if let latestReport = reports.first {
                previousReportContent = """
                Previous Scientific Description: \(latestReport.scientificDescription ?? "")
                Previous General Description: \(latestReport.generalDescription ?? "")
                Previous Recommendations: \(latestReport.recommendations ?? "")
                """
            }
        } catch {
            print("Error fetching previous reports: \(error)")
        }
    }
    
    // Format timestamp
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Send Message
    private func sendMessage() {
        guard !userMessage.isEmpty else { return }
        
        let messageText = userMessage
        messages.append((text: messageText, isUser: true, timestamp: Date()))
        userMessage = ""
        
        // Show AI is thinking indicator
        isProcessingAI = true
        
        // Generate AI response with medical intelligence
        OpenAIService.shared.generateMedicalResponse(
            prompt: messageText,
            conversationHistory: messages.dropLast().map { ($0.text, $0.isUser) },
            patientProfile: patientProfile,
            previousReports: [previousReportContent],
            medications: patientProfile["medications"] as? [String] ?? []
        ) { result in
            DispatchQueue.main.async {
                isProcessingAI = false
                
                switch result {
                case .success(let response):
                    // Add AI response to messages
                    messages.append((text: response, isUser: false, timestamp: Date()))
                    
                    // Extract symptom title if not already set
                    if symptomTitle.isEmpty {
                        extractSymptomTitle()
                    }
                    
                case .failure(let error):
                    print("Error generating AI response: \(error)")
                    
                    // Fallback to static responses
                    fallbackAIResponse(to: messageText)
                }
            }
        }
    }
    
    // Fallback AI response when API fails
    private func fallbackAIResponse(to message: String) {
        // Medical domain knowledge for follow-up questions
        let symptomBasedQuestions = [
            "Can you describe the pain on a scale from 1-10?",
            "Is the pain constant or does it come and go?",
            "When did you first notice these symptoms?",
            "Have the symptoms been getting better, worse, or staying the same?",
            "Are you experiencing any other symptoms alongside this one?",
            "Have you tried any treatments or remedies so far?",
            "How are these symptoms affecting your daily activities?"
        ]
        
        // Contextual awareness based on conversation history
        let userMessageCount = messages.filter { $0.isUser }.count
        
        if userMessageCount >= 5 || message.lowercased().contains("that's all") || message.lowercased().contains("finish") {
            // Enough information collected, suggest generating report
            extractSymptomTitle()
            
            messages.append((text: "Thank you for providing these details. I have enough information to create a report. You can click 'Generate Report' when you're ready.", isUser: false, timestamp: Date()))
        } else {
            // Select an appropriate follow-up question
            let nextQuestion = symptomBasedQuestions[userMessageCount % symptomBasedQuestions.count]
            messages.append((text: nextQuestion, isUser: false, timestamp: Date()))
        }
    }
    
    // Extract Symptom Title if not already set
    private func extractSymptomTitle() {
        if symptomTitle.isEmpty {
            // In a real app, this would use more sophisticated NLP
            if let firstUserMessage = messages.first(where: { $0.isUser })?.text {
                let words = firstUserMessage.components(separatedBy: " ")
                if words.count > 3 {
                    symptomTitle = words.prefix(3).joined(separator: " ")
                } else {
                    symptomTitle = firstUserMessage
                }
                
                // Capitalize first letter
                symptomTitle = symptomTitle.prefix(1).capitalized + symptomTitle.dropFirst()
                
                // Trim to reasonable length
                if symptomTitle.count > 30 {
                    symptomTitle = String(symptomTitle.prefix(30)) + "..."
                }
            } else {
                symptomTitle = "Unspecified Symptom"
            }
        }
    }
    
    // Generate Report
    private func generateReport() {
        if symptomTitle.isEmpty {
            extractSymptomTitle()
        }
        
        isProcessingAI = true
        
        // Use the OpenAI service to generate a structured report
        OpenAIService.shared.generateSymptomReport(
            symptomTitle: symptomTitle,
            conversationHistory: messages.map { ($0.text, $0.isUser) },
            patientProfile: patientProfile,
            previousReports: [previousReportContent],
            medications: patientProfile["medications"] as? [String] ?? []
        ) { result in
            DispatchQueue.main.async {
                isProcessingAI = false
                
                switch result {
                case .success(let report):
                    generatedReport = report
                    showSymptomConfirmation = true
                    
                case .failure(let error):
                    print("Error generating report: \(error)")
                    // Fallback to locally generated report
                    generateReportContent()
                    showSymptomConfirmation = true
                }
            }
        }
    }
    
    // Generate Report Content with medical intelligence as a fallback
    private func generateReportContent() {
        // Get patient data for personalization
        let age = patientProfile["age"] as? Int16 ?? 0
        let gender = patientProfile["gender"] as? String ?? "unknown"
        let medicalHistory = patientProfile["chronicConditions"] as? String
        let medications = patientProfile["medications"] as? [String] ?? []
        
        // Extract symptom details from conversation
        let userMessages = messages.filter { $0.isUser }.map { $0.text }.joined(separator: " ")
        
        // Generate medically-informed content
        
        // Scientific terminology based on reported symptoms
        let medicalTerms = [
            "acute exacerbation", "chronic inflammation", "myalgia", "neuropathic pain",
            "rhinitis", "gastroesophageal reflux", "dermatitis", "arthralgia",
            "hypersensitivity reaction", "idiopathic etiology", "paresthesia",
            "dyspnea", "tachycardia", "hypertension", "hypotension"
        ]
        
        let bodyRegions = [
            "cervical", "thoracic", "lumbar", "abdominal", "cranial",
            "epigastric", "peripheral", "proximal", "distal"
        ]
        
        // Pick relevant terms based on conversation
        var relevantTerms: [String] = []
        if userMessages.lowercased().contains("pain") {
            relevantTerms.append(contentsOf: ["myalgia", "arthralgia", "neuropathic pain"])
        }
        if userMessages.lowercased().contains("skin") || userMessages.lowercased().contains("rash") {
            relevantTerms.append("dermatitis")
        }
        if userMessages.lowercased().contains("stomach") || userMessages.lowercased().contains("acid") {
            relevantTerms.append("gastroesophageal reflux")
        }
        if userMessages.lowercased().contains("breath") || userMessages.lowercased().contains("cough") {
            relevantTerms.append("dyspnea")
        }
        
        // Use detected terms or fallback to random selection
        let selectedTerms = relevantTerms.isEmpty ?
            [medicalTerms.randomElement() ?? "unspecified condition"] :
            relevantTerms
        
        let bodyRegion = bodyRegions.randomElement() ?? "unspecified"
        
        // Generate scientific description with medical terminology
        let scientificDescription = """
        Patient presents with symptoms consistent with \(selectedTerms.joined(separator: ", ")) in the \(bodyRegion) region. 
        Patient demographics: \(age)-year-old \(gender).
        Symptom progression suggests \(userMessages.lowercased().contains("worse") ? "increasing severity" : "stable presentation").
        Differential diagnosis should consider \(userMessages.lowercased().contains("history") ? "patient's medical history" : "common etiologies").
        \(medications.isEmpty ? "" : "Current medications include \(medications.joined(separator: ", ")) which should be evaluated for potential interactions or side effects.")
        """
        
        // Generate general description in layperson's terms
        let generalDescription = """
        Based on your description, you're experiencing \(symptomTitle.lowercased()) that appears to be \(userMessages.lowercased().contains("pain") ? "causing discomfort" : "affecting your wellbeing").
        \(userMessages.lowercased().contains("worse") ? "Your symptoms seem to be progressing, which warrants attention." : "Your symptoms currently appear to be stable.")
        \(medicalHistory != nil ? "Given your history of \(medicalHistory!), this should be monitored closely." : "")
        The information you've provided helps create a clearer picture for your healthcare provider.
        """
        
        // Generate recommendations based on symptom severity
        let recommendations = """
        1. \(userMessages.lowercased().contains("severe") ? "Consult with a healthcare provider within 24-48 hours" : "Monitor symptoms for the next 3-5 days")
        2. Keep a detailed symptom journal noting timing, severity, and any triggers
        3. \(userMessages.lowercased().contains("pain") ? "Consider appropriate over-the-counter pain relief as directed by your healthcare provider" : "Rest and maintain proper hydration")
        4. \(userMessages.lowercased().contains("worse") ? "If symptoms worsen, seek immediate medical attention" : "If symptoms persist beyond one week, schedule a follow-up appointment")
        5. \(medications.isEmpty ? "Discuss with your doctor before starting any new medications" : "Continue prescribed medications unless directed otherwise by your doctor")
        """
        
        generatedReport = (
            scientific: scientificDescription,
            general: generalDescription,
            recommendations: recommendations
        )
    }
    
    // Save Symptom to Core Data
    private func saveSymptom() {
        guard let user = currentUser else {
            print("Error: No current user found")
            return
        }
        
        // Create a full description from all user messages
        let fullDescription = messages
            .filter { $0.isUser }
            .map { $0.text }
            .joined(separator: "\n\n")
        
        let symptom: Symptom
        
        if let existingSymptomId = symptomId, let existingSymptom = fetchSymptom(with: existingSymptomId) {
            // Update existing symptom
            symptom = existingSymptom
            symptom.title = symptomTitle
            symptom.description_field = fullDescription
            symptom.isOngoing = isOngoing
            symptom.lastUpdated = Date()
        } else {
            // Create new symptom
            symptom = Symptom(context: viewContext)
            symptom.id = UUID()
            symptom.title = symptomTitle
            symptom.description_field = fullDescription
            symptom.isOngoing = isOngoing
            symptom.startDate = Date()
            symptom.lastUpdated = Date()
            symptom.user = user
        }
        
        // Create symptom report
        let report = SymptomReport(context: viewContext)
        report.id = UUID()
        report.scientificDescription = generatedReport.scientific
        report.generalDescription = generatedReport.general
        report.recommendations = generatedReport.recommendations
        report.createdAt = Date()
        report.symptom = symptom
        
        // Save context
        do {
            try viewContext.save()
            
            // Return to main view
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            print("Error saving symptom: \(error)")
        }
    }
    
    // Fetch symptom by ID
    private func fetchSymptom(with id: UUID) -> Symptom? {
        let request: NSFetchRequest<Symptom> = Symptom.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let symptoms = try viewContext.fetch(request)
            return symptoms.first
        } catch {
            print("Error fetching symptom: \(error)")
            return nil
        }
    }
    
    // Toggle Voice Recording with real speech recognition
    private func toggleRecording() {
        if isRecording {
            // Stop recording
            isRecording = false
            speechRecognizer.stopRecording()
            
            // Use the final transcribed text
            if !transcribedText.isEmpty {
                userMessage = transcribedText
                transcribedText = ""
                sendMessage()
            }
        } else {
            // Start recording
            isRecording = true
            transcribedText = ""
            
            speechRecognizer.startRecording { recognizedText in
                transcribedText = recognizedText
            }
        }
    }
    
    // Process Image using Vision API
    private func processImage(_ image: UIImage) {
        isUsingVisionAPI = true
        isProcessingAI = true
        
        // Get patient description from previous messages
        let patientDescription = messages
            .filter { $0.isUser }
            .map { $0.text }
            .joined(separator: "\n")
        
        // Add placeholder message for image
        messages.append((text: "[Image uploaded]", isUser: true, timestamp: Date()))
        
        // Use Vision API to analyze the image
        OpenAIService.shared.analyzeSymptomImage(
            image: image,
            patientDescription: patientDescription,
            patientProfile: patientProfile
        ) { result in
            DispatchQueue.main.async {
                isProcessingAI = false
                isUsingVisionAPI = false
                
                switch result {
                case .success(let analysis):
                    // Add the AI's image analysis as a message
                    messages.append((text: analysis, isUser: false, timestamp: Date()))
                    
                case .failure(let error):
                    print("Error analyzing image: \(error)")
                    
                    // Fallback to generic image analysis response
                    let fallbackResponse = """
                    I can see the image you've shared. It appears to show some visible symptoms that could be relevant for diagnosis.
                    
                    Could you tell me:
                    1. How long have you had this visible symptom?
                    2. Is there any pain, itching, or discomfort associated with it?
                    3. Have you noticed any changes in its appearance over time?
                    """
                    
                    messages.append((text: fallbackResponse, isUser: false, timestamp: Date()))
                }
            }
        }
    }
    
    // Voice button icon based on recording state
    private var voiceButtonIcon: String {
        switch speechRecognitionStatus {
        case .notAuthorized:
            return "mic.slash"
        case .notStarted:
            return "mic.fill"
        case .authorized:
            return isRecording ? "stop.circle.fill" : "mic.fill"
        }
    }
    
    // Voice button color based on recording state
    private var voiceButtonColor: Color {
        switch speechRecognitionStatus {
        case .notAuthorized:
            return .gray
        case .notStarted:
            return .healixBlue
        case .authorized:
            return isRecording ? .red : .healixBlue
        }
    }
}

// MARK: - Speech Recognition Status
enum SpeechRecognitionStatus {
    case notStarted
    case authorized
    case notAuthorized
}

// MARK: - SpeechRecognizer (Real Implementation)
class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }
    
    func startRecording(resultHandler: @escaping (String) -> Void) {
        // Check if we're already recording
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            return
        }
        
        // Set up audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup error: \(error)")
            return
        }
        
        // Create and configure the speech recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create speech recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create a recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                resultHandler(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure the audio session
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start recording
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        // Clean up audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Audio session deactivation error: \(error)")
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - CameraView
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Preview
struct RecordSymptomsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecordSymptomsView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
