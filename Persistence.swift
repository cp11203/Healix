//
//  PersistenceController.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    // Check if store is loaded successfully
    var isStoreLoaded: Bool {
        return container.persistentStoreDescriptions.first?.url != nil &&
               container.persistentStoreCoordinator.persistentStores.count > 0
    }
    
    let container: NSPersistentContainer
    
    // A test configuration for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create sample users for preview
        let viewContext = controller.container.viewContext
        let testUser = User.createUser(username: "testuser", password: "password", in: viewContext)
        
        // Create demographics for the user
        let demographics = DemographicInfo(context: viewContext)
        demographics.id = UUID()
        demographics.age = 32
        demographics.gender = "Male"
        demographics.height = 175.0
        demographics.weight = 70.0
        demographics.bloodType = "A+"
        demographics.allergies = "Pollen, Dust"
        demographics.chronicConditions = "Asthma"
        demographics.user = testUser
        testUser.demographics = demographics
        
        // Create sample symptoms
        let symptom1 = Symptom.createSymptom(
            title: "Headache",
            description: "Persistent headache with pressure behind eyes",
            isOngoing: true,
            startDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            user: testUser,
            in: viewContext
        )
        
        let symptom2 = Symptom.createSymptom(
            title: "Cough",
            description: "Dry cough, especially at night",
            isOngoing: false,
            startDate: Date().addingTimeInterval(-86400 * 14), // 14 days ago
            user: testUser,
            in: viewContext
        )
        symptom2.lastUpdated = Date().addingTimeInterval(-86400 * 7) // Ended 7 days ago
        
        // Create sample reports
        _ = SymptomReport.createReport(
            scientificDescription: "Patient presents with symptoms consistent with tension headache. No neurological deficits observed.",
            generalDescription: "Your headache appears to be tension-related. It's likely caused by stress or posture issues.",
            recommendations: "Rest, hydration, and over-the-counter pain relievers may help. Consider stress reduction techniques.",
            symptom: symptom1,
            in: viewContext
        )
        
        _ = SymptomReport.createReport(
            scientificDescription: "Non-productive cough with nocturnal predominance suggests possible post-nasal drip or mild asthma exacerbation.",
            generalDescription: "Your dry cough that's worse at night could be related to allergies or mild asthma.",
            recommendations: "Stay hydrated, consider an antihistamine before bed, and monitor for any breathing difficulties.",
            symptom: symptom2,
            in: viewContext
        )
        
        // Create sample medications
        _ = Medication.createMedication(
            name: "Cetirizine",
            dosage: "10mg",
            frequency: "Once daily",
            startDate: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            endDate: nil, // Ongoing
            notes: "Take in the morning for allergy symptoms",
            user: testUser,
            in: viewContext
        )
        
        _ = Medication.createMedication(
            name: "Ibuprofen",
            dosage: "400mg",
            frequency: "As needed for pain",
            startDate: Date().addingTimeInterval(-86400 * 10), // 10 days ago
            endDate: Date().addingTimeInterval(-86400 * 5), // Ended 5 days ago
            notes: "For headache relief",
            user: testUser,
            in: viewContext
        )
        
        // Save the context
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Healix")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle error appropriately - log and present to user
                print("Persistent store loading error: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Check if entity exists in the model
    func entityExists(_ entityName: String) -> Bool {
        return NSEntityDescription.entity(forEntityName: entityName, in: container.viewContext) != nil
    }
    
    // Create a background context for operations
    func createBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    // Save a context with completion handler for error handling
    func saveContext(_ context: NSManagedObjectContext, completion: @escaping (Bool, Error?) -> Void) {
        if context.hasChanges {
            do {
                try context.save()
                completion(true, nil)
            } catch {
                // Handle error appropriately
                print("Context save error: \(error)")
                completion(false, error)
            }
        } else {
            completion(true, nil)
        }
    }
    
    // Convenience method to save view context with error handling
    func saveViewContext() throws {
        if container.viewContext.hasChanges {
            try container.viewContext.save()
        }
    }
    
    // Reset the Core Data stack (useful for logout functionality)
    func resetAllData() {
        // Delete each persistent store
        for store in container.persistentStoreCoordinator.persistentStores {
            do {
                try container.persistentStoreCoordinator.remove(store)
            } catch {
                print("Failed to remove persistent store: \(error)")
            }
        }
        
        // Recreate the persistent stores
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Persistent store loading error: \(error), \(error.userInfo)")
            }
        }
    }
    
    // Fetch user by ID
    func fetchUser(withId userId: UUID) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let users = try container.viewContext.fetch(request)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }
    
    // Execute a fetch request with error handling
    func executeFetchRequest<T>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Fetch request failed: \(error)")
            return []
        }
    }
}
