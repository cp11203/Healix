//
//  CoreDataModels.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//
import Foundation
import CoreData

// MARK: - Core Data Model Extensions

// User entity for authentication and profile information
extension User {
    // Convenience initializer for User entity
    @discardableResult
    static func createUser(
        username: String,
        password: String,
        in context: NSManagedObjectContext
    ) -> User {
        let user = User(context: context)
        user.id = UUID()
        user.username = username
        user.password = password
        user.createdAt = Date()
        return user
    }
}

// DemographicInfo entity for storing patient demographic information
extension DemographicInfo {
    // Convenience initializer for DemographicInfo entity
    @discardableResult
    static func createDemographicInfo(
        age: Int16,
        gender: String,
        height: Double,
        weight: Double,
        bloodType: String?,
        allergies: String?,
        chronicConditions: String?,
        user: User,
        in context: NSManagedObjectContext
    ) -> DemographicInfo {
        let demographicInfo = DemographicInfo(context: context)
        demographicInfo.id = UUID()
        demographicInfo.age = age
        demographicInfo.gender = gender
        demographicInfo.height = height
        demographicInfo.weight = weight
        demographicInfo.bloodType = bloodType
        demographicInfo.allergies = allergies
        demographicInfo.chronicConditions = chronicConditions
        demographicInfo.user = user
        return demographicInfo
    }
}

// Symptom entity for storing patient symptoms
extension Symptom {
    // Convenience initializer for Symptom entity
    @discardableResult
    static func createSymptom(
        title: String,
        description: String,
        isOngoing: Bool,
        startDate: Date,
        user: User,
        in context: NSManagedObjectContext
    ) -> Symptom {
        let symptom = Symptom(context: context)
        symptom.id = UUID()
        symptom.title = title
        symptom.description_field = description
        symptom.isOngoing = isOngoing
        symptom.startDate = startDate
        symptom.lastUpdated = Date()
        symptom.user = user
        return symptom
    }
    
    // Method to toggle between ongoing and acute
    func toggleOngoingStatus() {
        self.isOngoing.toggle()
        self.lastUpdated = Date()
    }
}

// SymptomReport entity for storing AI-generated symptom reports
extension SymptomReport {
    // Convenience initializer for SymptomReport entity
    @discardableResult
    static func createReport(
        scientificDescription: String,
        generalDescription: String,
        recommendations: String?,
        symptom: Symptom,
        in context: NSManagedObjectContext
    ) -> SymptomReport {
        let report = SymptomReport(context: context)
        report.id = UUID()
        report.scientificDescription = scientificDescription
        report.generalDescription = generalDescription
        report.recommendations = recommendations
        report.createdAt = Date()
        report.symptom = symptom
        return report
    }
}

// Medication entity for storing medication information
extension Medication {
    // Convenience initializer for Medication entity
    @discardableResult
    static func createMedication(
        name: String,
        dosage: String,
        frequency: String,
        startDate: Date,
        endDate: Date?,
        notes: String?,
        user: User,
        in context: NSManagedObjectContext
    ) -> Medication {
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = name
        medication.dosage = dosage
        medication.frequency = frequency
        medication.startDate = startDate
        medication.endDate = endDate
        medication.notes = notes
        medication.user = user
        return medication
    }
}
