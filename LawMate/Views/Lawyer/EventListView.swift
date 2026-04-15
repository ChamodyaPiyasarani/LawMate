import SwiftUI
import EventKit

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

// ... (previous EventRow code remains same)
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
