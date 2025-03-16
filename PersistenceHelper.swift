//
//  PersistenceHelper.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Helper functions for Core Data testing and initialization

extension PersistenceController {
    
    // Initialize the database with sample data if it's the first launch
    func initializeFirstLaunchData() {
        // Check if this is the first launch
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if isFirstLaunch {
            // Set the flag so this doesn't run next time
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            
            // Create sample data in the background
            let backgroundContext = createBackgroundContext()
            backgroundContext.perform {
                self.createSampleData(in: backgroundContext)
                
                // Save the context
                do {
                    try backgroundContext.save()
                    print("Sample data created successfully for first launch")
                } catch {
                    print("Failed to save sample data: \(error)")
                }
            }
        }
    }
    
    // Create sample data for testing or first launch
    private func createSampleData(in context: NSManagedObjectContext) {
        // Create a demo user
        let demoUser = User.createUser(
            username: "demo",
            password: "password",
            in: context
        )
        
        // Create demographics for the demo user
        let demographics = DemographicInfo(context: context)
        demographics.id = UUID()
        demographics.age = 35
        demographics.gender = "Female"
        demographics.height = 165.0
        demographics.weight = 65.0
        demographics.bloodType = "O+"
        demographics.allergies = "Penicillin"
        demographics.chronicConditions = "Asthma, Migraines"
        demographics.user = demoUser
        demoUser.demographics = demographics
        
        // Create sample symptoms
        let symptomTitles = ["Headache", "Cough", "Fever", "Sore Throat", "Fatigue"]
        let symptomDescriptions = [
            "Pounding pain in temples, worse in the morning",
            "Dry cough that gets worse at night",
            "Temperature of 100.4°F, chills, and sweating",
            "Painful throat, especially when swallowing",
            "Extreme tiredness and lack of energy"
        ]
        
        // Create a mix of ongoing and resolved symptoms
        for i in 0..<symptomTitles.count {
            let isOngoing = i % 2 == 0 // Even indices are ongoing
            let daysAgo = Double((i + 1) * 5) // Stagger start dates
            
            let symptom = Symptom.createSymptom(
                title: symptomTitles[i],
                description: symptomDescriptions[i],
                isOngoing: isOngoing,
                startDate: Date().addingTimeInterval(-86400 * daysAgo),
                user: demoUser,
                in: context
            )
            
            // For resolved symptoms, set an end date
            if !isOngoing {
                symptom.lastUpdated = Date().addingTimeInterval(-86400 * (daysAgo / 2))
            }
            
            // Create a report for each symptom
            createSampleReport(for: symptom, in: context)
        }
        
        // Create sample medications
        let medications = [
            (name: "Lisinopril", dosage: "10mg", frequency: "Once daily", ongoing: true, startDaysAgo: 60.0),
            (name: "Ibuprofen", dosage: "400mg", frequency: "As needed for pain", ongoing: false, startDaysAgo: 15.0),
            (name: "Albuterol", dosage: "2 puffs", frequency: "As needed for breathing", ongoing: true, startDaysAgo: 120.0)
        ]
        
        for med in medications {
            _ = Medication.createMedication(
                name: med.name,
                dosage: med.dosage,
                frequency: med.frequency,
                startDate: Date().addingTimeInterval(-86400 * med.startDaysAgo),
                endDate: med.ongoing ? nil : Date().addingTimeInterval(-86400 * (med.startDaysAgo / 3)),
                notes: "Sample medication for demo purposes",
                user: demoUser,
                in: context
            )
        }
    }
    
    // Create a sample symptom report
    private func createSampleReport(for symptom: Symptom, in context: NSManagedObjectContext) {
        let scientificDescriptions = [
            "Patient presents with cephalgia consistent with tension-type headache. No neurological deficits observed.",
            "Non-productive cough with nocturnal predominance suggests possible post-nasal drip or mild asthma exacerbation.",
            "Pyrexia of 38°C with associated myalgia and fatigue suggests viral etiology.",
            "Pharyngitis with erythema but no exudate. No lymphadenopathy observed.",
            "Generalized fatigue and malaise without associated fever or other symptoms. Potential causes include stress, overexertion, or mild dehydration."
        ]
        
        let generalDescriptions = [
            "Your headache appears to be tension-related. It's likely caused by stress or posture issues.",
            "Your dry cough that's worse at night could be related to allergies or mild asthma.",
            "Your fever with muscle aches suggests a viral infection like a cold or flu.",
            "Your sore throat appears mild without signs of strep or serious infection.",
            "Your fatigue may be related to stress, inadequate sleep, or mild dehydration."
        ]
        
        let recommendations = [
            "Rest, hydration, and over-the-counter pain relievers may help. Consider stress reduction techniques.",
            "Stay hydrated, consider an antihistamine before bed, and monitor for any breathing difficulties.",
            "Rest, hydration, and fever-reducing medication if uncomfortable. Seek medical attention if fever persists beyond 3 days.",
            "Warm salt water gargles, throat lozenges, and adequate hydration. Seek medical attention if symptoms worsen or persist beyond 5 days.",
            "Prioritize sleep, hydration, and balanced nutrition. Consider reducing stress and physical exertion temporarily."
        ]
        
        // Use symptom title to determine which text to use (defaulting to first if not found)
        let index = ["Headache", "Cough", "Fever", "Sore Throat", "Fatigue"].firstIndex(of: symptom.title ?? "") ?? 0
        
        _ = SymptomReport.createReport(
            scientificDescription: scientificDescriptions[index],
            generalDescription: generalDescriptions[index],
            recommendations: recommendations[index],
            symptom: symptom,
            in: context
        )
    }
    
    // Verify database schema integrity
    func verifyDatabaseSchema() -> Bool {
        let requiredEntities = ["User", "DemographicInfo", "Symptom", "SymptomReport", "Medication"]
        
        for entity in requiredEntities {
            if !entityExists(entity) {
                print("Database schema missing required entity: \(entity)")
                return false
            }
        }
        
        return true
    }
}

// MARK: - Helpful preview providers for development
extension PreviewProvider {
    static var dev: PersistenceController {
        return PersistenceController.preview
    }
}

// MARK: - Core Data Fetch Request Builders
extension PersistenceController {
    
    // Build a fetch request for symptoms by user
    func buildSymptomsFetchRequest(for userId: UUID, isOngoing: Bool? = nil) -> NSFetchRequest<Symptom> {
        let request: NSFetchRequest<Symptom> = Symptom.fetchRequest()
        
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "user.id == %@", userId as CVarArg))
        
        if let isOngoing = isOngoing {
            predicates.append(NSPredicate(format: "isOngoing == %@", NSNumber(value: isOngoing)))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Symptom.lastUpdated, ascending: false)]
        
        return request
    }
    
    // Build a fetch request for medications by user
    func buildMedicationsFetchRequest(for userId: UUID, isActive: Bool? = nil) -> NSFetchRequest<Medication> {
        let request: NSFetchRequest<Medication> = Medication.fetchRequest()
        
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "user.id == %@", userId as CVarArg))
        
        if let isActive = isActive {
            if isActive {
                // Active medications have no end date or end date in the future
                predicates.append(NSPredicate(format: "endDate == NULL OR endDate > %@", Date() as NSDate))
            } else {
                // Inactive medications have an end date in the past
                predicates.append(NSPredicate(format: "endDate != NULL AND endDate <= %@", Date() as NSDate))
            }
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.startDate, ascending: false)]
        
        return request
    }
}
