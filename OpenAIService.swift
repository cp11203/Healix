//
//  OpenAIService.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import Foundation
import UIKit

class OpenAIService {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1"
    
    // Use your actual OpenAI API key here - this should be stored more securely in a real application
    // such as in environment variables, secure storage, or retrieved from a secured backend service
    private let apiKey = "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"
    
    private init() {}
    
    // MARK: - Medical Response Generation
    
    /// Generates a medically-informed response for symptom recording conversations
    func generateMedicalResponse(
        prompt: String,
        conversationHistory: [(text: String, isUser: Bool)],
        patientProfile: [String: Any],
        previousReports: [String],
        medications: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let endpoint = "/chat/completions"
        let url = URL(string: baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the system prompt with medical context
        let systemPrompt = buildMedicalSystemPrompt(
            patientProfile: patientProfile,
            previousReports: previousReports,
            medications: medications
        )
        
        // Build messages from conversation history
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        // Add conversation history
        for message in conversationHistory {
            let role = message.isUser ? "user" : "assistant"
            messages.append(["role": role, "content": message.text])
        }
        
        // Add current query
        messages.append(["role": "user", "content": prompt])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo", // Using GPT-4 for medical knowledge and context
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 800
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            completion(.success(content))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Structured Report Generation
    
    /// Generates structured medical reports for symptoms
    func generateSymptomReport(
        symptomTitle: String,
        conversationHistory: [(text: String, isUser: Bool)],
        patientProfile: [String: Any],
        previousReports: [String],
        medications: [String],
        completion: @escaping (Result<(scientific: String, general: String, recommendations: String), Error>) -> Void
    ) {
        let endpoint = "/chat/completions"
        let url = URL(string: baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build system prompt for report generation
        let systemPrompt = """
        You are a medical AI assistant specialized in generating detailed medical reports based on patient-reported symptoms.
        Generate a three-part report in JSON format:
        1. Scientific Description: Use proper medical terminology and structure for healthcare professionals. Include likely etiology, differential diagnoses, and clinical assessment.
        2. General Description: Translate the medical assessment into clear, accessible language for the patient.
        3. Recommendations: Provide evidence-based, actionable advice and next steps. Include both immediate interventions and when to seek professional care.
        
        Patient Profile:
        \(formatPatientProfile(patientProfile))
        
        Current Medications:
        \(medications.joined(separator: ", "))
        
        Previous Medical Reports:
        \(previousReports.joined(separator: "\n"))
        
        Format your response EXACTLY as follows JSON (with no additional text):
        {
          "scientific": "Your scientific description here",
          "general": "Your general description here",
          "recommendations": "Your recommendations here"
        }
        """
        
        // Extract user messages to form symptom description
        let userMessages = conversationHistory.filter { $0.isUser }.map { $0.text }.joined(separator: "\n")
        
        // Create prompt for report generation
        let reportPrompt = """
        Symptom: \(symptomTitle)
        
        Patient Description:
        \(userMessages)
        
        Please generate a comprehensive medical report for this symptom.
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": reportPrompt]
            ],
            "temperature": 0.5,
            "max_tokens": 1500,
            "response_format": ["type": "json_object"]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        // Parse the JSON content
                        let decoder = JSONDecoder()
                        let reportData = content.data(using: .utf8)!
                        let report = try decoder.decode(SymptomReportResponse.self, from: reportData)
                        
                        DispatchQueue.main.async {
                            completion(.success((
                                scientific: report.scientific,
                                general: report.general,
                                recommendations: report.recommendations
                            )))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Health Trend Analysis
    
    /// Analyzes health trends and generates AI insights based on user's symptom history
    func generateHealthInsights(
        symptoms: [String],
        symptomDurations: [Int],
        patientProfile: [String: Any],
        medications: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let endpoint = "/chat/completions"
        let url = URL(string: baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format symptom data
        var symptomDetails = ""
        for (index, symptom) in symptoms.enumerated() {
            let duration = index < symptomDurations.count ? symptomDurations[index] : 0
            symptomDetails += "- \(symptom): Duration \(duration) days\n"
        }
        
        // Create system prompt for health insights
        let systemPrompt = """
        You are a medical AI assistant specializing in analyzing patient health data to identify patterns and provide personalized health insights.
        
        Guidelines:
        1. Analyze correlations between symptoms, medications, and patient profile
        2. Identify potential triggers or factors contributing to symptoms
        3. Suggest lifestyle modifications based on evidence-based medicine
        4. Highlight patterns that may warrant medical attention
        5. Keep insights evidence-based, clear, and actionable
        6. Do not provide definitive diagnoses but suggest possibilities
        7. Include appropriate disclaimers about consulting healthcare providers
        
        Patient Profile:
        \(formatPatientProfile(patientProfile))
        
        Current Medications:
        \(medications.joined(separator: ", "))
        """
        
        // Create user prompt with symptoms
        let userPrompt = """
        Based on my health profile and the following symptoms, please provide health insights:
        
        Symptoms:
        \(symptomDetails)
        
        What patterns do you notice? Are there any insights about my health you can share?
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.5,
            "max_tokens": 1000
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            completion(.success(content))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Vision API for Symptom Image Analysis
    
    /// Analyzes symptom images using OpenAI's Vision model
    func analyzeSymptomImage(
        image: UIImage,
        patientDescription: String,
        patientProfile: [String: Any],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let endpoint = "/chat/completions"
        let url = URL(string: baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])))
            return
        }
        let base64Image = imageData.base64EncodedString()
        
        // Create system prompt for image analysis
        let systemPrompt = """
        You are a medical AI assistant specialized in visual symptom analysis. Your role is to:
        
        1. Analyze visible symptoms from images with medical precision
        2. Relate visual findings to patient-reported symptoms
        3. Identify potential medical implications of visible symptoms
        4. Suggest relevant follow-up questions to gather more information
        5. Remain professional while using accessible language
        6. Include appropriate medical disclaimers
        
        Remember to focus on visible characteristics without making definitive diagnoses, and note when further professional evaluation is needed.
        
        Patient Profile:
        \(formatPatientProfile(patientProfile))
        """
        
        // Format patient description
        let userPrompt = """
        I'm experiencing the following symptoms:
        \(patientDescription)
        
        I've uploaded an image showing the visible symptoms. Please analyze this image and provide your medical assessment.
        """
        
        // Create messages array with image content
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            [
                "role": "user",
                "content": [
                    ["type": "text", "text": userPrompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": messages,
            "temperature": 0.5,
            "max_tokens": 800
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            completion(.success(content))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Builds a comprehensive medical system prompt for symptom conversation
    private func buildMedicalSystemPrompt(
        patientProfile: [String: Any],
        previousReports: [String],
        medications: [String]
    ) -> String {
        """
        You are a medical AI assistant specialized in gathering and analyzing symptom information with clinical precision.
        
        Your responsibilities include:
        1. Ask focused clinical questions to gather complete symptom information using established medical frameworks (OPQRST, etc.)
        2. Adapt questions based on patient demographics, medical history, and current medications
        3. Demonstrate empathy while maintaining clinical objectivity
        4. Follow evidence-based medical questioning patterns
        5. Ask about symptom characteristics: onset, duration, severity, quality, location, context, aggravating/alleviating factors, and associated symptoms
        
        You have medical knowledge that includes:
        - Standard medical terminology and frameworks
        - Common medication classes and their side effects
        - Understanding of symptom patterns for common medical conditions
        - Awareness of red flags requiring urgent medical attention
        
        Patient Profile:
        \(formatPatientProfile(patientProfile))
        
        Current Medications:
        \(medications.joined(separator: ", "))
        
        Previous Medical Reports:
        \(previousReports.joined(separator: "\n\n"))
        
        Use this information to provide context-aware, personalized follow-up questions to gather a comprehensive symptom history.
        Remember to maintain a conversational tone while collecting clinically relevant information.
        """
    }
    
    /// Formats patient profile into a readable string
    private func formatPatientProfile(_ profile: [String: Any]) -> String {
        var result = ""
        
        if let age = profile["age"] as? Int16 {
            result += "Age: \(age)\n"
        }
        
        if let gender = profile["gender"] as? String {
            result += "Gender: \(gender)\n"
        }
        
        if let height = profile["height"] as? Double {
            result += "Height: \(height) cm\n"
        }
        
        if let weight = profile["weight"] as? Double {
            result += "Weight: \(weight) kg\n"
        }
        
        if let bloodType = profile["bloodType"] as? String {
            result += "Blood Type: \(bloodType)\n"
        }
        
        if let allergies = profile["allergies"] as? String {
            result += "Allergies: \(allergies)\n"
        }
        
        if let chronicConditions = profile["chronicConditions"] as? String {
            result += "Chronic Conditions: \(chronicConditions)\n"
        }
        
        return result
    }
}

// MARK: - Response Models

/// Structure to decode symptom report responses
struct SymptomReportResponse: Codable {
    let scientific: String
    let general: String
    let recommendations: String
}
