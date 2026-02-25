// Models/WorkoutModels.swift
// SwiftData models — all stored encrypted locally on-device.
// No iCloud sync by default. No data ever leaves the device.

import Foundation
import SwiftData

// MARK: - WorkoutSession
// Represents one full workout (e.g. "Bicep Curl, Monday 9am")

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var exerciseName: String
    var targetSets: Int
    var targetReps: Int
    var durationSeconds: Int
    var averageFormScore: Double      // 0.0 – 1.0
    var completedSets: Int
    var totalRepsCompleted: Int
    var notes: String

    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet]

    init(
        exerciseName: String,
        targetSets: Int,
        targetReps: Int
    ) {
        self.id = UUID()
        self.date = Date()
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.durationSeconds = 0
        self.averageFormScore = 0
        self.completedSets = 0
        self.totalRepsCompleted = 0
        self.notes = ""
        self.sets = []
    }

    /// Human-readable form score e.g. "87%"
    var formScoreText: String {
        "\(Int(averageFormScore * 100))%"
    }

    /// Summary line for history list
    var summary: String {
        "\(completedSets)/\(targetSets) sets · \(totalRepsCompleted) reps · \(formScoreText) form"
    }
}

// MARK: - ExerciseSet
// One set within a session (e.g. Set 2: 10 reps, form 0.91)

@Model
final class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var repsCompleted: Int
    var formScore: Double             // 0.0 – 1.0
    var completedAt: Date

    init(setNumber: Int, repsCompleted: Int, formScore: Double) {
        self.id = UUID()
        self.setNumber = setNumber
        self.repsCompleted = repsCompleted
        self.formScore = formScore
        self.completedAt = Date()
    }
}
