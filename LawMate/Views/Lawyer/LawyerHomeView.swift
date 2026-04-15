import SwiftUI
import EventKit

enum LawyerRoute: Hashable {
    case addCase
    case uploadAdvisory
}

struct LawyerHomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userRole") private var storedRole: UserRole = .lawyer
    @State private var selectedTab: LawMateTab = .home
    @State private var navPath = NavigationPath()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.lmBackground.ignoresSafeArea()
            
            NavigationStack(path: $navPath) {
                VStack(spacing: 0) {
                    if selectedTab == .home {
                        // MARK: Lawyer Home Dashboard
                        ZStack(alignment: .top) {
                            // Fixed Background Blob (Right-aligned for Lawyer)
                            GreenBlobBackground(style: .lawyer)
                                .frame(height: 350)
                                .offset(y: -50) // Adjust to sit behind header
                            
                            VStack(spacing: 0) {
                                // MARK: Fixed Header (Sticky)
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Welcome to LawMate !")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.lmPrimary)

                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("Justice,")
                                                .font(.lmHero)
                                                .foregroundColor(.lmPrimary)
                                            Text("Refined.")
                                                .font(.lmHero)
                                                .foregroundColor(.lmTextSecondary.opacity(0.5))
                                        }
                                    }
                                    Spacer()
                                    
                                    // Notification Bell as per image
                                    NotificationButton(badgeCount: 3, action: {})
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 64)
                                .background(Color.lmBackground.opacity(0.01)) // Subtle touch area

                                // MARK: Scrollable Content
                                ScrollView(showsIndicators: false) {
                                    VStack(alignment: .leading, spacing: 28) {
                                        // MARK: Stats Cards
                                        HStack(spacing: 20) {
                                            DashboardStatCard(title: "Cases", value: "07", isGreen: false)
                                            DashboardStatCard(title: "Today\nAppointments", value: "03", isGreen: true)
                                        }
                                        .padding(.horizontal, 24)

                                        // MARK: Hearings Card
                                        HearingsCard(count: "09")
                                            .padding(.horizontal, 24)

                                        // MARK: Action Buttons
                                        HStack(spacing: 16) {
                                            ActionPill(icon: "plus.circle.fill", title: "Add new case") {
                                                navPath.append(LawyerRoute.addCase)
                                            }
                                            ActionPill(icon: "doc.badge.plus", title: "Add Documents") {
                                                navPath.append(LawyerRoute.uploadAdvisory)
                                            }
                                        }
                                        .padding(.horizontal, 24)

                                        // MARK: Schedules
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Today Schedules")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.lmTextSecondary.opacity(0.6))
                                                .padding(.horizontal, 24)

                                            VStack(spacing: 16) {
                                                ScheduleRow(time: "10.00 AM", event: "Consultation : Anuradha Rnasinghe", category: "Family Law")
                                                ScheduleRow(time: "02.00 PM", event: "Hearing : Malsha Kavindi", category: "Divorce")
                                            }
                                            .padding(.horizontal, 24)
                                        }

                                        // TabBar Space
                                        Color.clear.frame(height: 120)
                                    }
                                    .padding(.top, 24)
                                }
                            }
                        }
                        .ignoresSafeArea(edges: .top)
                    } else if selectedTab == .cases {
                        LawyerCasesView()
                    } else if selectedTab == .calendar {
                        LawyerCalendarView(showBack: false)
                    } else if selectedTab == .messages {
                        MessagesListView(onBack: { selectedTab = .home })
                    } else {
                        ProfileView(onBack: { selectedTab = .home })
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(for: ChatPreview.self) { chat in
                    ChatDetailView(chat: chat)
                }
                .navigationDestination(for: LawyerRoute.self) { route in
                    switch route {
                    case .addCase:
                        AddCaseView()
                    case .uploadAdvisory:
                        UploadAdvisoryView()
                    }
                }
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .personalInfo:
                        PersonalInfoView()
                    case .security:
                        SecurityView()
                    case .biometrics:
                        BiometricsView()
                    case .profileNotifications:
                        ProfileNotificationsView()
                    case .termsOfService:
                        TermsView()
                    case .privacyPolicy:
                        PrivacyView()
                    case .myUploads:
                        LawyerMyUploadsView()
                    }
                }
            }
            
            // MARK: Global Tab Bar (Lawyer Role)
            if navPath.isEmpty {
                VStack {
                    Spacer()
                    TabBarView(selectedTab: $selectedTab, role: .lawyer)
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: navPath.isEmpty)
        .onChange(of: selectedTab) { _ in
            navPath = NavigationPath()
        }
    }
}

// MARK: - Subcomponents

private struct DashboardStatCard: View {
    let title: String
    let value: String
    let isGreen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(isGreen ? .white : .lmPrimary)
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isGreen ? .white : .lmTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(isGreen ? Color.lmPrimary : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

private struct HearingsCard: View {
    let count: String

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.lmPrimary.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.lmPrimary)
            }
            
            Text("Hearings\nThis Week")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.lmPrimary)
            
            Spacer()
            
            Text(count)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.lmTextSecondary.opacity(0.3))
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

private struct ActionPill: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 6)
            .padding(.trailing, 16)
            .padding(.vertical, 6)
            .background(Color(red: 0.05, green: 0.25, blue: 0.15)) // Darker green for pills
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ScheduleRow: View {
    let time: String
    let event: String
    let category: String

    var body: some View {
        HStack(spacing: 16) {
            // Minimalist timeline indicator
            VStack {
                Text(time.split(separator: " ").first ?? "")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.lmTextPrimary)
                Text(time.split(separator: " ").last ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmTextPrimary.opacity(0.6))
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Text(category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.lmTextSecondary.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            HStack {
                Rectangle()
                    .fill(Color.lmPrimary)
                    .frame(width: 4)
                    .padding(.vertical, 12)
                Spacer()
            }
        )
    }
}

private struct ComingSoonView: View {
    let title: String
    let icon: String
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color.lmBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                LawMateNavigationBar(title: title, showBack: true, showNotification: false, onBack: onBack)
                    .padding(.top, 64)
                
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.lmPrimary.opacity(0.3))
                Text("\(title) coming soon")
                    .font(.lmBody)
                    .foregroundColor(.lmTextSecondary)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    LawyerHomeView()
}

// MARK: - Lawyer Calendar Components

struct LawyerCalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @Environment(\.dismiss) private var dismiss
    var showBack: Bool = true
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.lmBackground.ignoresSafeArea()
            
            // Lawyer Style Background
            GreenBlobBackground(style: .lawyer)
                .frame(height: 350)
                .offset(y: -50)
            
            VStack(spacing: 0) {
                // MARK: Left-Aligned Header
                HStack(alignment: .center) {
                    Text("My Calendar")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Spacer()
                    
                    NotificationButton(badgeCount: 3, action: {})
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 24)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: Calendar Card
                        calendarCard
                        
                        // MARK: Event List
                        EventListView(viewModel: viewModel)
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.requestAccess()
            viewModel.refreshMonthData()
        }
    }
    
    private var calendarCard: some View {
        VStack(spacing: 20) {
            // Month Selector
            HStack {
                Button {
                    withAnimation { viewModel.previousMonth() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lmPrimary)
                }
                
                Spacer()
                
                Text(viewModel.currentMonth, formatter: monthYearFormatter)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.lmPrimary)
                
                Spacer()
                
                Button {
                    withAnimation { viewModel.nextMonth() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lmPrimary)
                }
            }
            .padding(.horizontal, 10)
            
            // Weekday Headings
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lmTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid
            let days = generateDaysInMonth(for: viewModel.currentMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, viewModel: viewModel)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.5), lineWidth: 1))
        .padding(.horizontal, 24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmptyDays = weekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        
        for day in 1...monthRange.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var monthYearFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }
}

struct EventListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var showingAddEvent = false
    @State private var newEventTitle = ""
    @State private var selectedType = "Appointment"
    
    let eventTypes = ["Appointment", "Hearing", "Consultation"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule for \(viewModel.selectedDate, formatter: dateFormatter)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lmPrimary)
                    
                    Text("\(viewModel.eventsForSelectedDate.count) Events scheduled")
                        .font(.system(size: 13))
                        .foregroundColor(.lmTextSecondary)
                }
                
                Spacer()
                
                if viewModel.eventsForSelectedDate.count < 3 {
                    Button {
                        showingAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.lmPrimary)
                    }
                } else {
                    Text("Day Full")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            
            if viewModel.eventsForSelectedDate.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.lmPrimary.opacity(0.2))
                    Text("No appointments for this day.")
                        .font(.system(size: 14))
                        .foregroundColor(.lmTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.eventsForSelectedDate, id: \.eventIdentifier) { event in
                        EventRow(event: event)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            addEventSheet
        }
    }
    
    private var addEventSheet: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $newEventTitle)
                    Picker("Type", selection: $selectedType) {
                        ForEach(eventTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddEvent = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addEvent(title: newEventTitle, type: selectedType)
                        newEventTitle = ""
                        showingAddEvent = false
                    }
                    .disabled(newEventTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }
}

struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text(event.startDate, formatter: timeFormatter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.lmPrimary)
                Rectangle()
                    .fill(Color.lmPrimary.opacity(0.2))
                    .frame(width: 2, height: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.lmPrimary)
                
                if let notes = event.notes {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(.lmTextSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: typeIcon)
                .foregroundColor(typeColor)
                .font(.system(size: 18))
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.5), lineWidth: 1))
    }
    
    private var typeIcon: String {
        if event.title.contains("Hearing") { return "gavel.fill" }
        if event.title.contains("Consultation") { return "person.2.fill" }
        return "calendar"
    }
    
    private var typeColor: Color {
        if event.title.contains("Hearing") { return .red }
        if event.title.contains("Consultation") { return .blue }
        return .lmPrimary
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}

struct DayCell: View {
    let date: Date
    @ObservedObject var viewModel: CalendarViewModel
    
    private var isSelected: Bool {
        Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Button {
            withAnimation(.spring()) {
                viewModel.selectDate(date)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.getColor(for: date))
                    .frame(width: 38, height: 38)
                
                if isSelected {
                    Circle()
                        .stroke(Color.lmPrimary, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
                
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 16, weight: isToday || isSelected ? .bold : .medium))
                        .foregroundColor(viewModel.getTextColor(for: date))
                    
                    // Busy indicator dot if needed
                    Circle()
                        .fill(viewModel.getStatusColor(for: date))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
