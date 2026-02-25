// Views/HistoryView.swift
// Shows all past workout sessions stored locally on-device.

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    @State private var sessionToDelete: WorkoutSession?

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("")
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "333350"))
            Text("No workouts yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "555570"))
            Text("Complete a workout to see your history here.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "333350"))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Session List

    var sessionList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Workout History")
                        .font(.custom("Georgia-Bold", size: 24))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(sessions.count) sessions")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "444460"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Weekly stats bar
                weeklyStatsRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Session cards
                LazyVStack(spacing: 10) {
                    ForEach(sessions) { session in
                        SessionCard(session: session)
                            .padding(.horizontal, 20)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(session)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Weekly Stats

    var weeklyStatsRow: some View {
        let weekSessions = sessions.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }
        let avgForm = weekSessions.isEmpty ? 0.0 :
            weekSessions.map(\.averageFormScore).reduce(0, +) / Double(weekSessions.count)

        return HStack(spacing: 12) {
            MiniStat(value: "\(weekSessions.count)", label: "This week", color: "5BC8FF")
            MiniStat(value: "\(sessions.count)", label: "All time", color: "00C896")
            MiniStat(value: "\(Int(avgForm * 100))%", label: "Avg form", color: "FFB740")
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 14) {
            // Exercise emoji
            Text(ExerciseLibrary.exercise(id: session.exerciseName.lowercased().replacingOccurrences(of: " ", with: "_"))?.emoji ?? "🏋️")
                .font(.system(size: 28))
                .frame(width: 50, height: 50)
                .background(Color(hex: "1E1E2E"))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.exerciseName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(session.summary)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666680"))
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "444460"))
            }

            Spacer()

            // Form score badge
            VStack(spacing: 2) {
                Text(session.formScoreText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(formColor(session.averageFormScore))
                Text("FORM")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(hex: "444460"))
                    .kerning(0.5)
            }
        }
        .padding(14)
        .background(Color(hex: "14141E"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "1E1E2E"), lineWidth: 1))
    }

    func formColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return Color(hex: "00C896")
        case 0.6..<0.8: return Color(hex: "5BC8FF")
        case 0.4..<0.6: return Color(hex: "FFB740")
        default: return Color(hex: "FF5A5A")
        }
    }
}

// MARK: - Mini Stat

struct MiniStat: View {
    let value: String
    let label: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "555570"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "14141E"))
        .cornerRadius(12)
    }
}
