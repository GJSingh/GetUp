// Services/HealthKitManager.swift
// Writes completed workouts to Apple Health (calories, duration, workout type).
// Uses HKWorkoutBuilder (iOS 17+) — replaces deprecated HKWorkout + add(_:to:) API.
//
// SETUP: Add HealthKit capability in Xcode:
//   Target → Signing & Capabilities → + Capability → HealthKit
// Add to build settings INFOPLIST keys:
//   NSHealthUpdateUsageDescription → "GetUp saves your workout duration and calories to Apple Health."

import Foundation
import HealthKit

// MARK: - HealthKitManager

final class HealthKitManager {

    static let shared = HealthKitManager()
    private init() {}

    private let store = HKHealthStore()

    // appleExerciseTime is system-only — Apple writes it automatically.
    // Requesting share permission for it throws a crash at runtime.
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned)
    ]

    // MARK: - Availability

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorisation

    func requestAuthorisation(completion: @escaping (Bool) -> Void) {
        guard isAvailable else { completion(false); return }

        // Safety check: if NSHealthUpdateUsageDescription is missing from Info.plist,
        // requestAuthorization throws a hard exception. Check for the key first.
        guard Bundle.main.object(forInfoDictionaryKey: "NSHealthUpdateUsageDescription") != nil else {
            print("[HealthKit] NSHealthUpdateUsageDescription missing from Info.plist — skipping.")
            completion(false)
            return
        }

        store.requestAuthorization(toShare: writeTypes, read: []) { granted, error in
            DispatchQueue.main.async {
                if let error { print("[HealthKit] Auth error: \(error)") }
                completion(granted)
            }
        }
    }

    var isAuthorised: Bool {
        guard isAvailable else { return false }
        return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    // MARK: - Save Workout
    // Uses HKWorkoutBuilder (modern API, not deprecated)

    func saveWorkout(
        exerciseId:       String,
        exerciseName:     String,
        startDate:        Date,
        durationSeconds:  Int,
        averageFormScore: Double,
        totalReps:        Int
    ) {
        guard isAvailable, isAuthorised, durationSeconds > 0 else { return }

        let endDate      = startDate.addingTimeInterval(TimeInterval(durationSeconds))
        let activityType = hkActivityType(for: exerciseId)
        let calories     = estimateCalories(exerciseId: exerciseId, durationSeconds: durationSeconds)

        // Build workout config
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store,
                                       configuration: config,
                                       device: .local())

        builder.beginCollection(withStart: startDate) { success, error in
            guard success else {
                print("[HealthKit] beginCollection error: \(String(describing: error))")
                return
            }

            // Add active energy sample
            let energyType     = HKQuantityType(.activeEnergyBurned)
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let energySample   = HKQuantitySample(type: energyType,
                                                   quantity: energyQuantity,
                                                   start: startDate,
                                                   end: endDate)

            builder.add([energySample]) { success, error in
                if let error { print("[HealthKit] add sample error: \(error)") }

                builder.endCollection(withEnd: endDate) { success, error in
                    if let error { print("[HealthKit] endCollection error: \(error)"); return }

                    builder.finishWorkout { workout, error in
                        if let error {
                            print("[HealthKit] finishWorkout error: \(error)")
                        } else {
                            print("[HealthKit] Saved: \(exerciseName), \(Int(calories)) kcal, \(durationSeconds)s")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Calorie Estimation (MET formula: cal = MET × 70kg × hours)

    private func estimateCalories(exerciseId: String, durationSeconds: Int) -> Double {
        let met: Double
        switch exerciseId {
        case "squat", "jumping_jacks":             met = 6.0
        case "bicep_curl", "shoulder_press",
             "lateral_raise", "tricep_extension":  met = 4.5
        case "warrior_one", "warrior_two",
             "chair_pose":                         met = 3.5
        case "tree_pose", "downward_dog":          met = 2.5
        default:                                   met = 4.0
        }
        return met * 70.0 * (Double(durationSeconds) / 3600.0)
    }

    // MARK: - Activity Type Mapping

    private func hkActivityType(for exerciseId: String) -> HKWorkoutActivityType {
        switch exerciseId {
        case "bicep_curl", "shoulder_press",
             "lateral_raise", "tricep_extension",
             "squat":                             return .traditionalStrengthTraining
        case "jumping_jacks":                     return .jumpRope
        case "warrior_one", "warrior_two",
             "tree_pose", "downward_dog",
             "chair_pose":                        return .yoga
        default:                                  return .functionalStrengthTraining
        }
    }
}
