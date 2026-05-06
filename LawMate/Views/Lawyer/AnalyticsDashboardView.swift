import SwiftUI

struct AnalyticsDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firestore: FirestoreManager

    private var totalCases: Int { firestore.cases.count }

    private var closedCases: Int {
        firestore.cases.filter { caseItem in
            let status = caseItem.status.lowercased()
            return status == "closed" || status == "completed" || status == "resolved"
        }.count
    }

    private var activeCases: Int { max(totalCases - closedCases, 0) }

    private var averageProgress: Double {
        let cases = firestore.cases
        guard !cases.isEmpty else { return 0 }
        let total = cases.reduce(0.0) { $0 + $1.progressProgress }
        return total / Double(cases.count)
    }

    private var overdueTasks: Int {
        let now = Date()
        return firestore.caseTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return due < now && task.status.lowercased() != "done"
        }.count
    }

    private var dueSoonTasks: Int {
        let now = Date()
        let upcoming = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return firestore.caseTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return due >= now && due <= upcoming && task.status.lowercased() != "done"
        }.count
    }

    private var statusBuckets: [(String, Int)] {
        let statuses = ["pending", "active", "in progress", "closed"]
        return statuses.map { status in
            let count = firestore.cases.filter { $0.status.lowercased() == status }.count
            return (status.capitalized, count)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            GreenBlobBackground(style: .lawyer)
                .frame(height: 300)

            VStack(spacing: 0) {
                LawMateNavigationBar(title: "Case Analytics", showBack: true, onBack: { dismiss() })
                    .padding(.top, 65)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        summaryCards

                        progressCard

                        statusChart

                        caseProgressList

                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricCard(title: "Total Cases", value: String(format: "%02d", totalCases))
                MetricCard(title: "Active Cases", value: String(format: "%02d", activeCases))
            }
            HStack(spacing: 12) {
                MetricCard(title: "Overdue Tasks", value: String(format: "%02d", overdueTasks))
                MetricCard(title: "Due in 7 Days", value: String(format: "%02d", dueSoonTasks))
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Case Progress")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lmTextSecondary)

            HStack {
                Text("\(Int(averageProgress * 100))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Spacer()
            }

            ProgressView(value: averageProgress)
                .tint(.lmPrimary)
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }

    private var statusChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Case Status Breakdown")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lmTextSecondary)

            VStack(spacing: 10) {
                ForEach(statusBuckets, id: \.0) { label, count in
                    HStack(spacing: 12) {
                        Text(label)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.lmTextSecondary)
                            .frame(width: 90, alignment: .leading)

                        GeometryReader { geo in
                            let ratio = totalCases == 0 ? 0 : CGFloat(count) / CGFloat(totalCases)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.lmPrimary.opacity(0.2))
                                .frame(height: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.lmPrimary)
                                        .frame(width: geo.size.width * ratio, height: 10),
                                    alignment: .leading
                                )
                        }
                        .frame(height: 10)

                        Text("\(count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.lmPrimary)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }

    private var caseProgressList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Case Progress")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.lmTextSecondary)

            if firestore.cases.isEmpty {
                Text("No cases yet.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(firestore.cases.prefix(6)) { legalCase in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(legalCase.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.lmPrimary)
                                Spacer()
                                Text("\(Int(legalCase.progressProgress * 100))%")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.lmTextSecondary)
                            }
                            ProgressView(value: legalCase.progressProgress)
                                .tint(.lmPrimary)
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lmPrimary.opacity(0.1), lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

private struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.lmTextSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.lmPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.7))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}
