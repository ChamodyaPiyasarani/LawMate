import SwiftUI

struct LawyerCalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @Environment(\.dismiss) private var dismiss
    @Binding var navPath: NavigationPath
    @Binding var activeConversation: FBConversation?
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
                    
                    NotificationButton()
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                .padding(.bottom, 24)
                
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
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Calendar Access Required")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "0F4D33")) // LawMate Dark Green
                    .multilineTextAlignment(.center)
                
                Text("To manage your hearings and appointments, LawMate needs access to your iOS Calendar.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            Button {
                viewModel.requestAccess()
            } label: {
                Text("Grant Access")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 260, height: 64)
                    .background(Color(hex: "1A4331")) // Dark variant for button
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                // Placeholder to keep layout stable if needed, or just let it expand
                Text("Calendar access is required to manage your appointments.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.bottom, 60)
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
                ForEach(days) { day in
                    if let date = day.date {
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
    
    private func generateDaysInMonth(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmptyDays = weekday - 1
        
        var days: [CalendarDay] = []
        
        // Add leading empty days
        for _ in 0..<leadingEmptyDays {
            days.append(CalendarDay(date: nil))
        }
        
        // Add actual days
        for day in 1...monthRange.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date))
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
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
}
#Preview {
    LawyerCalendarView(navPath: .constant(NavigationPath()), activeConversation: .constant(nil))
}
