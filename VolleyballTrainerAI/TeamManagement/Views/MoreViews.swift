import SwiftUI
import SwiftData

// MARK: - Schedule View

struct ScheduleView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedDate = Date()
    @State private var showAttendanceSheet = false
    @State private var attendanceEvent: CalendarEvent?
    
    var body: some View {
        VStack(spacing: 14) {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .colorScheme(.dark)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(NeonGlassStyle.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)
                        )
                )
            
            let events = (team.events ?? []).filter {
                Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate)
            }.sorted { $0.startDate < $1.startDate }
            
            if events.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No events on this day")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(events) { event in
                    EventRow(event: event)
                        .onTapGesture { viewModel.selectedEvent = event }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                let upcoming = (team.events ?? []).filter { $0.startDate > Date() }
                    .sorted { $0.startDate < $1.startDate }.prefix(5)
                
                if upcoming.isEmpty {
                    Text("No upcoming events")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ForEach(Array(upcoming)) { event in
                        EventCompactRow(event: event)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NeonGlassStyle.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(event.startDate.formatted(.dateTime.day()))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(event.startDate.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(width: 40)
            
            Circle()
                .fill(event.eventType == .matchDay ? Color.green : Color.blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Image(systemName: event.eventType.iconName)
                        .font(.caption2)
                    Text(event.formattedDateRange)
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Image(systemName: event.eventType.iconName)
                    .foregroundColor(event.eventType == .matchDay ? .green : .blue)
                Text(event.eventType.rawValue)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NeonGlassStyle.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Event Compact Row

struct EventCompactRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(event.eventType == .matchDay ? Color.green : Color.blue)
                .frame(width: 6, height: 6)
            Text(event.title)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            Text(event.startDate, style: .date)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Chat List View

struct ChatListView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedRoom: ChatRoom?
    @State private var messageText = ""
    @State private var showNewRoomSheet = false
    
    var body: some View {
        VStack(spacing: 14) {
            if let room = selectedRoom {
                // Chat room view
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { selectedRoom = nil }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                        Text(room.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            let msgs = (room.messages ?? []).sorted { $0.timestamp < $1.timestamp }
                            ForEach(msgs) { msg in
                                ChatBubbleView(message: msg)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack(spacing: 8) {
                        TextField("Type a message...", text: $messageText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        
                        Button(action: {
                            guard !messageText.isEmpty else { return }
                            let msg = ChatMessage(
                                senderID: UUID(),
                                senderName: "Coach",
                                senderRole: "headCoach",
                                content: messageText
                            )
                            viewModel.sendMessage(msg, to: room, context: modelContext)
                            messageText = ""
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            } else {
                // Room list
                let rooms = team.chatRooms ?? []
                
                ForEach(rooms) { room in
                    ChatRoomRow(room: room)
                        .onTapGesture { selectedRoom = room }
                }
                
                if rooms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No Chat Rooms")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Create a chat room to communicate with your team.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                }
                
                Button(action: {
                    let room = ChatRoom(name: "Team Chat", roomType: "team")
                    viewModel.createChatRoom(room, for: team, context: modelContext)
                }) {
                    Label("Create Team Chat", systemImage: "plus.bubble")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Chat Room Row

struct ChatRoomRow: View {
    let room: ChatRoom
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(NeonGlassStyle.neonGradient(), lineWidth: 1.5)
                    )
                Image(systemName: room.roomType == "coaches" ? "person.2.fill" : "bubble.left.and.bubble.right.fill")
                    .foregroundColor(room.roomType == "coaches" ? .blue : .pink)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(room.lastMessagePreview.isEmpty ? "No messages yet" : room.lastMessagePreview)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(room.lastMessageTimestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if room.unreadCount > 0 {
                    Text("\(room.unreadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.pink)
                        )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NeonGlassStyle.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Chat Bubble View

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isCoachMessage {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isCoachMessage ? .trailing : .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(message.senderName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(message.isCoachMessage ? .blue : .pink)
                    Text(message.formattedTime)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                
                if message.isSystemMessage {
                    Text(message.content)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    Text(message.content)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(message.isCoachMessage ? Color.blue.opacity(0.2) : Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            message.isCoachMessage ? Color.blue.opacity(0.3) : Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                        )
                }
            }
            
            if !message.isCoachMessage {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Paperwork List View

struct PaperworkListView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedPaperwork: PaperworkRequirement?
    
    var body: some View {
        VStack(spacing: 14) {
            if let paperwork = selectedPaperwork {
                PaperworkDetailView(paperwork: paperwork, viewModel: viewModel)
                Button(action: { selectedPaperwork = nil }) {
                    Text("Back to List")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            } else {
                let paperworks = team.paperworks ?? []
                
                if paperworks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No Paperwork")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(paperworks) { paper in
                        PaperworkRow(paperwork: paper)
                            .onTapGesture { selectedPaperwork = paper }
                    }
                }
                
                // Quick add from templates
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Add from Templates")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                    
                    ForEach(PaperworkPresets.allTemplates, id: \.category) { category in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.category)
                                .font(.caption)
                                .foregroundColor(.pink)
                            
                            ForEach(category.items, id: \.id) { template in
                                Button(action: {
                                    let newPaperwork = PaperworkRequirement(
                                        title: template.title,
                                        type: template.type,
                                        descriptionText: template.descriptionText,
                                        isRequired: template.isRequired
                                    )
                                    viewModel.createPaperwork(newPaperwork, for: team, context: modelContext)
                                }) {
                                    HStack {
                                        Text("+ \(template.title)")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NeonGlassStyle.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Paperwork Row

struct PaperworkRow: View {
    let paperwork: PaperworkRequirement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: paperwork.type == .physical ? "heart.text.square" : "doc.text")
                .font(.title3)
                .foregroundColor(paperwork.isRequired ? .pink : .blue)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(paperwork.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(paperwork.type.rawValue)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if paperwork.isRequired {
                        Text("REQUIRED")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                // Completion progress
                let counts = paperwork.statusCounts
                let total = counts.submitted + counts.verified + counts.pending + counts.rejected + counts.expired
                let done = counts.submitted + counts.verified
                
                Text("\(done)/\(total)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                if let due = paperwork.dueDate, due < Date() {
                    Text("Overdue")
                        .font(.system(size: 9))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NeonGlassStyle.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Paperwork Detail View

struct PaperworkDetailView: View {
    let paperwork: PaperworkRequirement
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Text(paperwork.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(paperwork.descriptionText)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                let counts = paperwork.statusCounts
                let total = counts.submitted + counts.verified + counts.pending + counts.rejected + counts.expired
                
                // Progress bar
                VStack(spacing: 4) {
                    HStack {
                        Text("Completion: \(counts.verified)/\(total) verified")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.0f%%", paperwork.completionRate * 100))
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(NeonGlassStyle.neonGradient())
                                .frame(width: geo.size.width * paperwork.completionRate, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NeonGlassStyle.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)
                    )
            )
            
            // Submissions list
            ForEach(paperwork.submissions ?? []) { submission in
                SubmissionRow(submission: submission)
                    .contextMenu {
                        if submission.status == .submitted {
                            Button(action: {
                                viewModel.verifySubmission(submission, verifiedByName: "Coach", context: modelContext)
                            }) {
                                Label("Verify", systemImage: "checkmark.circle")
                            }
                            Button(action: {
                                viewModel.rejectSubmission(submission, reason: "Incomplete", context: modelContext)
                            }) {
                                Label("Reject", systemImage: "xmark.circle")
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Submission Row

struct SubmissionRow: View {
    let submission: PaperworkSubmission
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(submission.memberName.isEmpty ? "Unknown" : submission.memberName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                if let submitted = submission.submittedAt {
                    Text("Submitted: \(submitted.formatted())")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(submission.statusDisplay)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(submission.statusColor.opacity(0.3))
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(NeonGlassStyle.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}