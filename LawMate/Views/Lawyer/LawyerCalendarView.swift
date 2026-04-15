import SwiftUI

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
                // MARK: Custom Header
                LawMateNavigationBar(
                    title: "My Calendar",
                    showBack: showBack,
                    onBack: { dismiss() }
                )
                .padding(.top, 64)
                
                if !viewModel.isAuthorized {
                    permissionView
                } else {
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
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.refreshMonthData()
        }
    }
    
    // MARK: - Subviews
    
    private var permissionView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "calendar.badge.shield.half.filled")
                .font(.system(size: 80))
                .foregroundColor(.lmPrimary.opacity(0.3))
            
            Text("Calendar Access Required")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.lmPrimary)
            
            Text("To manage your hearings and appointments, LawMate needs access to your iOS Calendar.")
                .font(.system(size: 15))
                .foregroundColor(.lmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                viewModel.requestAccess()
            } label: {
                Text("Grant Access")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.lmPrimary)
                    .clipShape(Capsule())
            }
            .padding(.top, 20)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            Spacer()
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
    
    // MARK: - Helper Logic
    
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
