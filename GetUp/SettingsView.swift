// Views/SettingsView.swift
// App settings + analytics dashboard.
// Analytics uses Swift Charts (iOS 16+, available since app targets iOS 17).

import SwiftUI
import SwiftData
import Charts

struct SettingsView: View {
    @AppStorage("hapticFeedback")     private var hapticFeedback = true
    @AppStorage("showSkeletonAlways") private var showSkeleton   = true
    @AppStorage("defaultRestSeconds") private var defaultRest    = 60

    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirm = false
    @State private var selectedAnalyticsTab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Analytics Header ──────────────────────────────────
                    analyticsHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // ── Chart Tab Picker ──────────────────────────────────
                    if !sessions.isEmpty {
                        chartTabPicker
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        chartCard
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    } else {
                        emptyState
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                    }

                    // ── Settings Sections ─────────────────────────────────
                    settingsSections
                        .padding(.top, 24)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(hex: "0A0A0F").ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirm) {
            Button("Delete Everything", role: .destructive) {
                for s in sessions { modelContext.delete(s) }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All \(sessions.count) sessions will be permanently deleted.")
        }
    }

    // MARK: - Analytics Header (stat pills)

    private var analyticsHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Progress")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                StatPill(value: "\(sessions.count)",
                         label: "Workouts",
                         icon: "figure.strengthtraining.traditional",
                         color: "00C896")
                StatPill(value: "\(totalReps)",
                         label: "Total Reps",
                         icon: "repeat",
                         color: "5BC8FF")
                StatPill(value: "\(Int(avgFormScore * 100))%",
                         label: "Avg Form",
                         icon: "chart.line.uptrend.xyaxis",
                         color: formScoreColor)
                StatPill(value: totalTimeString,
                         label: "Total Time",
                         icon: "clock",
                         color: "FFB347")
            }
        }
    }

    // MARK: - Chart Tab Picker

    private var chartTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(["Weekly", "Form", "Exercises"], id: \.self) { tab in
                let idx = ["Weekly", "Form", "Exercises"].firstIndex(of: tab)!
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedAnalyticsTab = idx
                    }
                } label: {
                    Text(tab)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedAnalyticsTab == idx
                                         ? Color(hex: "0A0A0F")
                                         : Color(hex: "666680"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedAnalyticsTab == idx
                                ? Color(hex: "00C896")
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color(hex: "14141E"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Chart Card

    @ViewBuilder
    private var chartCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "111120"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "1E1E35"), lineWidth: 1)
                )

            switch selectedAnalyticsTab {
            case 0: weeklyChart.padding(20)
            case 1: formTrendChart.padding(20)
            case 2: exerciseBreakdownChart.padding(20)
            default: EmptyView()
            }
        }
        .frame(height: 240)
    }

    // MARK: - Weekly Workouts Bar Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workouts this week")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "666680"))

            Chart(last7DaysData) { point in
                BarMark(
                    x: .value("Day", point.label),
                    y: .value("Workouts", point.value)
                )
                .foregroundStyle(Color(hex: "00C896"))
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...max(4, last7DaysData.map(\.value).max() ?? 4))
            .chartXAxis {
                AxisMarks { mark in
                    AxisValueLabel()
                        .foregroundStyle(Color(hex: "555570"))
                        .font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 1)) { mark in
                    AxisGridLine().foregroundStyle(Color(hex: "1E1E35"))
                    AxisValueLabel()
                        .foregroundStyle(Color(hex: "555570"))
                        .font(.system(size: 10))
                }
            }
        }
    }

    // MARK: - Form Trend Line Chart

    private var formTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Form score (last 10 sessions)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "666680"))

            Chart(formTrendData) { point in
                LineMark(
                    x: .value("Session", point.label),
                    y: .value("Score", point.value * 100)
                )
                .foregroundStyle(Color(hex: "5BC8FF"))
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Session", point.label),
                    y: .value("Score", point.value * 100)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "5BC8FF").opacity(0.25),
                                 Color(hex: "5BC8FF").opacity(0)],
                        startPoint: .top, endPoint: .bottom)
                )

                PointMark(
                    x: .value("Session", point.label),
                    y: .value("Score", point.value * 100)
                )
                .foregroundStyle(Color(hex: "5BC8FF"))
                .symbolSize(30)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(Color(hex: "555570")).font(.system(size: 10)) }
            }
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { mark in
                    AxisGridLine().foregroundStyle(Color(hex: "1E1E35"))
                    AxisValueLabel {
                        if let v = mark.as(Int.self) {
                            Text("\(v)%").font(.system(size: 10)).foregroundStyle(Color(hex: "555570"))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Exercise Breakdown Bar Chart

    private var exerciseBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top exercises")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "666680"))

            Chart(exerciseBreakdownData.prefix(5)) { point in
                BarMark(
                    x: .value("Sessions", point.value),
                    y: .value("Exercise", point.label)
                )
                .foregroundStyle(Color(hex: "FFB347"))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(point.value)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "888899"))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) { mark in
                    AxisGridLine().foregroundStyle(Color(hex: "1E1E35"))
                    AxisValueLabel().foregroundStyle(Color(hex: "555570")).font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(Color(hex: "888899")).font(.system(size: 10)) }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "333350"))
            Text("No workouts yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "555570"))
            Text("Complete your first workout to see analytics here.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "3A3A55"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(hex: "111120"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Settings Sections

    private var settingsSections: some View {
        VStack(spacing: 16) {
            // Feedback
            SettingsSection(title: "Feedback") {
                SettingsToggleRow(label: "Haptic Feedback",
                                  icon: "iphone.radiowaves.left.and.right",
                                  value: $hapticFeedback)
                Divider().background(Color(hex: "1E1E2E"))
                SettingsToggleRow(label: "Show Skeleton Overlay",
                                  icon: "figure.stand",
                                  value: $showSkeleton)
            }

            // Defaults
            SettingsSection(title: "Defaults") {
                HStack {
                    Label("Rest Duration", systemImage: "bed.double")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Stepper("\(defaultRest)s",
                            value: $defaultRest,
                            in: 15...180, step: 15)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "00C896"))
                }
                .padding(.vertical, 2)
            }

            // Data
            SettingsSection(title: "Your Data") {
                HStack {
                    Label("Sessions Saved", systemImage: "square.stack")
                        .font(.system(size: 15)).foregroundStyle(.white)
                    Spacer()
                    Text("\(sessions.count)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "666680"))
                }
                Divider().background(Color(hex: "1E1E2E"))
                Button {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete All Workout Data", systemImage: "trash")
                        .font(.system(size: 15))
                        .foregroundStyle(.red)
                }
            }

            // Privacy
            SettingsSection(title: "Privacy") {
                PrivacyRow(icon: "lock.shield.fill",
                           title: "100% On-Device",
                           bodyText: "Pose detection runs on Apple's Neural Engine. No video leaves your phone.")
                Divider().background(Color(hex: "1E1E2E"))
                PrivacyRow(icon: "wifi.slash",
                           title: "No Network Requests",
                           bodyText: "GetUp makes zero network requests. No account, no analytics, no ads.")
                Divider().background(Color(hex: "1E1E2E"))
                PrivacyRow(icon: "internaldrive",
                           title: "Local Storage Only",
                           bodyText: "History lives in your private, encrypted app sandbox.")
            }

            // About
            SettingsSection(title: "About") {
                HStack {
                    Text("Version").font(.system(size: 15)).foregroundStyle(.white)
                    Spacer()
                    Text("1.0.0").foregroundStyle(Color(hex: "666680"))
                }
            }
        }
    }

    // MARK: - Computed Analytics Data

    private var totalReps: Int {
        sessions.map(\.totalRepsCompleted).reduce(0, +)
    }

    private var avgFormScore: Double {
        guard !sessions.isEmpty else { return 0 }
        return sessions.map(\.averageFormScore).reduce(0, +) / Double(sessions.count)
    }

    private var formScoreColor: String {
        avgFormScore >= 0.80 ? "00C896" : avgFormScore >= 0.50 ? "FFB347" : "FF5F5F"
    }

    private var totalTimeString: String {
        let secs = sessions.map(\.durationSeconds).reduce(0, +)
        let hrs  = secs / 3600
        let mins = (secs % 3600) / 60
        if hrs > 0 { return "\(hrs)h \(mins)m" }
        return "\(mins)m"
    }

    /// Last 7 calendar days: count of sessions per day
    private var last7DaysData: [ChartPoint] {
        let cal  = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset -> ChartPoint in
            let day   = cal.date(byAdding: .day, value: -offset, to: today)!
            let count = sessions.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            let label = offset == 0 ? "Today"
                      : offset == 1 ? "Yest."
                      : dayAbbrev(day)
            return ChartPoint(label: label, value: count)
        }
    }

    /// Form scores for the last 10 sessions (oldest → newest)
    private var formTrendData: [ChartPoint] {
        let recent = Array(sessions.prefix(10).reversed())
        return recent.enumerated().map { i, s in
            ChartPoint(label: "#\(i+1)", value: s.averageFormScore)
        }
    }

    /// Sessions per exercise name, sorted by count descending
    private var exerciseBreakdownData: [ChartPoint] {
        var counts: [String: Int] = [:]
        for s in sessions { counts[s.exerciseName, default: 0] += 1 }
        return counts
            .map { ChartPoint(label: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    private func dayAbbrev(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return String(fmt.string(from: date).prefix(3))
    }
}

// MARK: - Supporting Types

private struct ChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
    init(label: String, value: Int)   { self.label = label; self.value = value }
    init(label: String, value: Double) { self.label = label; self.value = Int(value * 100) }
}

// MARK: - Reusable Setting Subviews

private struct StatPill: View {
    let value: String
    let label: String
    let icon:  String
    let color: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(hex: "555570"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "111120"))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color(hex: color).opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "444460"))
                .kerning(1)

            VStack(spacing: 0) {
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .background(Color(hex: "111120"))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "1E1E35"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct SettingsToggleRow: View {
    let label: String
    let icon:  String
    @Binding var value: Bool

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $value)
                .tint(Color(hex: "00C896"))
                .labelsHidden()
        }
    }
}

private struct PrivacyRow: View {
    let icon:     String
    let title:    String
    let bodyText: String   // renamed from `body` to avoid conflict with View.body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "00C896"))
                .frame(width: 24)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(bodyText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "555570"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}
