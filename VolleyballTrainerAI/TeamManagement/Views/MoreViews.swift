import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import EventKit

// MARK: - Schedule View (Calendar)

struct ScheduleView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var showRSVPSheet = false
    @State private var rsvpEvent: CalendarEvent?
    @State private var syncAlert = false

    var body: some View {
        VStack(spacing: 12) {
            // Calendar date picker
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .colorScheme(.dark)
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))

            let events = (team.events ?? []).filter {
                Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate)
            }.sorted { $0.startDate < $1.startDate }

            if events.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock").font(.largeTitle).foregroundColor(.gray)
                    Text("No events on this day").font(.system(size: 16, design: .rounded)).foregroundColor(.gray)
                }.padding(.vertical, 40)
            } else {
                ForEach(events) { event in
                    EventRow(event: event)
                        .onTapGesture { rsvpEvent = event; showRSVPSheet = true }
                        .contextMenu {
                            if event.requiresRSVP {
                                Button { rsvpEvent = event; showRSVPSheet = true } label: { Label("RSVP", systemImage: "checkmark") }
                            }
                            Button { syncToAppleCalendar(event) } label: { Label("Sync to Calendar", systemImage: "calendar.badge.plus") }
                            Button(role: .destructive) { deleteEvent(event) } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }

            // Upcoming events
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming Events").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                let upcoming = (team.events ?? []).filter { $0.startDate > Date() }.sorted { $0.startDate < $1.startDate }.prefix(8)
                if upcoming.isEmpty {
                    Text("No upcoming events").font(.caption).foregroundColor(.gray)
                } else {
                    ForEach(Array(upcoming)) { event in
                        EventCompactRow(event: event)
                            .contextMenu {
                                Button { syncToAppleCalendar(event) } label: { Label("Sync to Calendar", systemImage: "calendar.badge.plus") }
                            }
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))

            // Sync all button
            Button {
                syncAllToAppleCalendar()
            } label: {
                Label("Sync All Events to Apple Calendar", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.5), lineWidth: 1)))
            }
        }
        .sheet(isPresented: $showRSVPSheet) {
            if let event = rsvpEvent {
                RSVPView(event: event, viewModel: viewModel)
            }
        }
        .alert("Calendar Synced", isPresented: $syncAlert) {
            Button("OK") { }
        } message: {
            Text("Event has been added to your Apple Calendar.")
        }
    }

    private func syncToAppleCalendar(_ event: CalendarEvent) {
        let store = EKEventStore()
        store.requestFullAccessToEvents { granted, _ in
            guard granted else { return }
            let ekEvent = EKEvent(eventStore: store)
            ekEvent.title = event.title
            ekEvent.startDate = event.startDate
            ekEvent.endDate = event.endDate
            ekEvent.notes = event.notes
            ekEvent.location = event.location
            ekEvent.calendar = store.defaultCalendarForNewEvents
            do {
                try store.save(ekEvent, span: .thisEvent)
                DispatchQueue.main.async { syncAlert = true }
            } catch {
                print("Calendar sync error: \(error)")
            }
        }
    }

    private func syncAllToAppleCalendar() {
        guard let events = team.events, !events.isEmpty else { return }
        let store = EKEventStore()
        store.requestFullAccessToEvents { granted, _ in
            guard granted else { return }
            for event in events {
                let ekEvent = EKEvent(eventStore: store)
                ekEvent.title = event.title
                ekEvent.startDate = event.startDate
                ekEvent.endDate = event.endDate
                ekEvent.notes = event.notes
                ekEvent.location = event.location
                ekEvent.calendar = store.defaultCalendarForNewEvents
                try? store.save(ekEvent, span: .thisEvent)
            }
            DispatchQueue.main.async { syncAlert = true }
        }
    }

    private func deleteEvent(_ event: CalendarEvent) {
        modelContext.delete(event)
        try? modelContext.save()
    }
}

// MARK: - Event Row
struct EventRow: View {
    let event: CalendarEvent
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(event.startDate.formatted(.dateTime.day())).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text(event.startDate.formatted(.dateTime.month(.abbreviated))).font(.caption2).foregroundColor(.gray)
            }.frame(width: 40)
            Circle().fill(event.eventType == .matchDay ? Color.green : Color.blue).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white)
                HStack(spacing: 6) {
                    Image(systemName: event.eventType.iconName).font(.caption2)
                    Text(event.formattedDateRange).font(.caption2)
                }.foregroundColor(.gray)
                if event.requiresRSVP {
                    let attending = (event.rsvpResponses ?? []).filter { $0.status == .attending }.count
                    Text("\(attending) attending").font(.caption2).foregroundColor(.green)
                }
            }
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: event.eventType.iconName).foregroundColor(event.eventType == .matchDay ? .green : .blue)
                Text(event.durationFormatted).font(.system(size: 8)).foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1)))
    }
}

// MARK: - Event Compact Row
struct EventCompactRow: View {
    let event: CalendarEvent
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(event.eventType == .matchDay ? Color.green : Color.blue).frame(width: 6, height: 6)
            Text(event.title).font(.system(size: 13, design: .rounded)).foregroundColor(.white).lineLimit(1)
            Spacer()
            Text(event.startDate, style: .date).font(.caption2).foregroundColor(.gray)
        }.padding(.vertical, 3)
    }
}

// MARK: - RSVP View

struct RSVPView: View {
    let event: CalendarEvent
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var memberName = ""
    @State private var selectedStatus: RSVPStatus = .attending
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))

                VStack(spacing: 16) {
                    Text(event.title).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text(event.formattedDateRange).font(.caption).foregroundColor(.gray)

                    GlassTextField(title: "Your Name", text: $memberName, placeholder: "Name")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Status").font(.caption).foregroundColor(.gray)
                        Picker("Status", selection: $selectedStatus) {
                            ForEach([RSVPStatus.attending, RSVPStatus.maybe, RSVPStatus.declined], id: \.rawValue) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    GlassTextField(title: "Note (optional)", text: $note, placeholder: "")

                    Button {
                        viewModel.recordRSVP(event: event, memberID: UUID(), memberName: memberName.isEmpty ? "Anonymous" : memberName, status: selectedStatus, context: modelContext)
                        dismiss()
                    } label: {
                        Text("Submit RSVP").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()))
                    }
                }
                .padding()
            }
            .navigationTitle("RSVP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
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
    @State private var newRoomName = ""
    @State private var newRoomType = "team"

    var body: some View {
        VStack(spacing: 14) {
            if let room = selectedRoom {
                chatRoomView(room: room)
            } else {
                let rooms = team.chatRooms ?? []

                ForEach(rooms) { room in
                    ChatRoomRow(room: room)
                        .onTapGesture { selectedRoom = room }
                }

                if rooms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right").font(.largeTitle).foregroundColor(.gray)
                        Text("No Chat Rooms").font(.headline).foregroundColor(.gray)
                        Text("Create a chat room to communicate with your team.").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                    }.padding(.vertical, 40)
                }

                HStack(spacing: 10) {
                    Button {
                        let room = ChatRoom(name: "Team Chat", roomType: "team")
                        viewModel.createChatRoom(room, for: team, context: modelContext)
                    } label: {
                        Label("Team", systemImage: "bubble.left.and.bubble.right").font(.caption).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.pink.opacity(0.5), lineWidth: 1))
                    }
                    Button {
                        let room = ChatRoom(name: "Coaches Chat", roomType: "coaches", isCoachOnlyPosting: true)
                        viewModel.createChatRoom(room, for: team, context: modelContext)
                    } label: {
                        Label("Coaches", systemImage: "person.2.fill").font(.caption).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.5), lineWidth: 1))
                    }
                    Button {
                        let room = ChatRoom(name: "Parent Board", roomType: "parents", isCoachOnlyPosting: true)
                        viewModel.createChatRoom(room, for: team, context: modelContext)
                    } label: {
                        Label("Parents", systemImage: "megaphone").font(.caption).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.5), lineWidth: 1))
                    }
                }
            }
        }
    }

    private func chatRoomView(room: ChatRoom) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { selectedRoom = nil }) {
                    Image(systemName: "chevron.left").foregroundColor(.blue)
                }
                Text(room.name).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                if room.isCoachOnlyPosting {
                    Image(systemName: "lock.fill").font(.caption2).foregroundColor(.orange)
                }
                Spacer()
            }
            .padding(.horizontal).padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 8) {
                    let msgs = (room.messages ?? []).sorted { $0.timestamp < $1.timestamp }
                    ForEach(msgs) { msg in
                        ChatBubbleView(message: msg)
                    }
                }.padding(.horizontal)
            }

            HStack(spacing: 8) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.plain).foregroundColor(.white).padding(10)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                Button {
                    guard !messageText.isEmpty else { return }
                    let msg = ChatMessage(senderID: UUID(), senderName: "Coach", senderRole: "headCoach", content: messageText)
                    viewModel.sendMessage(msg, to: room, context: modelContext)
                    messageText = ""
                } label: {
                    Image(systemName: "paperplane.fill").foregroundColor(.blue).padding(10)
                        .background(Circle().fill(Color.blue.opacity(0.2)))
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }
}

// MARK: - Chat Room Row
struct ChatRoomRow: View {
    let room: ChatRoom
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.black.opacity(0.7)).frame(width: 42, height: 42)
                    .overlay(Circle().stroke(NeonGlassStyle.neonGradient(), lineWidth: 1.5))
                Image(systemName: room.roomType == "coaches" ? "person.2.fill" : (room.roomType == "parents" ? "megaphone.fill" : "bubble.left.and.bubble.right.fill"))
                    .foregroundColor(room.roomType == "coaches" ? .blue : (room.roomType == "parents" ? .green : .pink))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(room.name).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                    if room.isCoachOnlyPosting {
                        Image(systemName: "lock.fill").font(.caption2).foregroundColor(.orange)
                    }
                }
                Text(room.lastMessagePreview.isEmpty ? "No messages yet" : room.lastMessagePreview)
                    .font(.caption).foregroundColor(.gray).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(room.lastMessageTimestamp, style: .time).font(.caption2).foregroundColor(.gray)
                if room.unreadCount > 0 {
                    Text("\(room.unreadCount)").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Color.pink))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1)))
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isCoachMessage { Spacer(minLength: 50) }
            VStack(alignment: message.isCoachMessage ? .trailing : .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(message.senderName).font(.system(size: 10, weight: .semibold))
                        .foregroundColor(message.isCoachMessage ? .blue : .pink)
                    Text(message.formattedTime).font(.system(size: 9)).foregroundColor(.gray)
                }
                if message.isSystemMessage {
                    Text(message.content).font(.system(size: 12, design: .rounded)).foregroundColor(.gray).italic()
                } else {
                    Text(message.content).font(.system(size: 14, design: .rounded)).foregroundColor(.white)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(message.isCoachMessage ? Color.blue.opacity(0.2) : Color.black.opacity(0.6))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(message.isCoachMessage ? Color.blue.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)))
                }
            }
            if !message.isCoachMessage { Spacer(minLength: 50) }
        }
    }
}

// MARK: - Messaging / Notification View

struct MessagingView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var recipientGroup = "all_players"
    @State private var sendSMS = false
    @State private var sendEmail = true
    @State private var showSentAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recipient Group").font(.caption).foregroundColor(.gray)
                            Picker("Group", selection: $recipientGroup) {
                                Text("All Players").tag("all_players")
                                Text("All Coaches").tag("all_coaches")
                                Text("All Parents").tag("all_parents")
                                Text("All Members").tag("all_members")
                            }
                            .pickerStyle(.segmented)
                        }

                        GlassTextField(title: "Subject", text: $subject, placeholder: "Message subject")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Message Body").font(.caption).foregroundColor(.gray)
                            TextEditor(text: $messageBody).frame(height: 120).foregroundColor(.white).padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.6))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                                .scrollContentBackground(.hidden)
                        }
                        Toggle("Send as Email", isOn: $sendEmail).tint(.pink).foregroundColor(.white)
                        Toggle("Send as SMS", isOn: $sendSMS).tint(.pink).foregroundColor(.white)

                        Button {
                            showSentAlert = true
                        } label: {
                            Text("Send Message").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()))
                                .opacity(subject.isEmpty || messageBody.isEmpty ? 0.5 : 1)
                        }
                        .disabled(subject.isEmpty || messageBody.isEmpty)
                    }
                    .padding()
                }
            }
            .alert("Message Sent", isPresented: $showSentAlert) {
                Button("OK") { subject = ""; messageBody = "" }
            } message: {
                Text("Your message has been sent to \(recipientGroup.replacingOccurrences(of: "_", with: " ")).")
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
    @State private var showFileUploadSheet = false
    @State private var uploadPaperwork: PaperworkRequirement?

    var body: some View {
        VStack(spacing: 14) {
            if let paperwork = selectedPaperwork {
                PaperworkDetailView(paperwork: paperwork, viewModel: viewModel, onUpload: {
                    uploadPaperwork = paperwork
                    showFileUploadSheet = true
                })
                Button { selectedPaperwork = nil } label: {
                    Text("Back to List").font(.caption).foregroundColor(.blue)
                }
            } else {
                let paperworks = team.paperworks ?? []

                if paperworks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text").font(.largeTitle).foregroundColor(.gray)
                        Text("No Paperwork").font(.headline).foregroundColor(.gray)
                        Text("Add paperwork requirements from the templates below or create a custom form.").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                    }.padding(.vertical, 40)
                } else {
                    ForEach(paperworks) { paper in
                        PaperworkRow(paperwork: paper)
                            .onTapGesture { selectedPaperwork = paper }
                            .contextMenu {
                                Button {
                                    uploadPaperwork = paper
                                    showFileUploadSheet = true
                                } label: { Label("Upload File", systemImage: "doc.badge.plus") }
                            }
                    }
                }

                // Quick add from templates
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Add").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.gray)
                    ForEach(PaperworkPresets.allTemplates, id: \.category) { category in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.category).font(.caption).foregroundColor(.pink)
                            ForEach(category.items, id: \.id) { template in
                                Button {
                                    let newPaperwork = PaperworkRequirement(
                                        title: template.title, type: template.type,
                                        descriptionText: template.descriptionText, isRequired: template.isRequired
                                    )
                                    viewModel.createPaperwork(newPaperwork, for: team, context: modelContext)
                                } label: {
                                    HStack {
                                        Text("+ \(template.title)").font(.caption2).foregroundColor(.blue)
                                        Spacer()
                                    }.padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))

                // Create custom form button
                Button {
                    viewModel.showCreatePaperwork = true
                } label: {
                    Label("Create Custom Form", systemImage: "square.and.pencil")
                        .font(.caption).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1))
                }
            }
        }
        .sheet(isPresented: $showFileUploadSheet) {
            if let paperwork = uploadPaperwork {
                FileUploadView(paperwork: paperwork, viewModel: viewModel)
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
                .font(.title3).foregroundColor(paperwork.isRequired ? .pink : .blue)
            VStack(alignment: .leading, spacing: 3) {
                Text(paperwork.title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(paperwork.type.rawValue).font(.caption2).foregroundColor(.gray)
                    if paperwork.isRequired {
                        Text("REQUIRED").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
                            .padding(.horizontal, 4).padding(.vertical, 1).background(Capsule().fill(Color.red.opacity(0.2)))
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                let counts = paperwork.statusCounts
                let total = counts.submitted + counts.verified + counts.pending + counts.rejected + counts.expired
                let done = counts.submitted + counts.verified
                Text("\(done)/\(total)").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.green)
                if let due = paperwork.dueDate, due < Date() {
                    Text("Overdue").font(.system(size: 9)).foregroundColor(.red)
                }
                HStack(spacing: 2) {
                    ProgressView(value: paperwork.completionRate).tint(.green).frame(width: 40)
                    Text(String(format: "%.0f%%", paperwork.completionRate * 100)).font(.system(size: 9)).foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1)))
    }
}

// MARK: - Paperwork Detail View
struct PaperworkDetailView: View {
    let paperwork: PaperworkRequirement
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    let onUpload: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Text(paperwork.title).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text(paperwork.descriptionText).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                let counts = paperwork.statusCounts
                let total = counts.submitted + counts.verified + counts.pending + counts.rejected + counts.expired
                VStack(spacing: 4) {
                    HStack {
                        Text("Completion: \(counts.verified)/\(total) verified").font(.caption2).foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.0f%%", paperwork.completionRate * 100)).font(.caption2).foregroundColor(.green)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4).fill(NeonGlassStyle.neonGradient()).frame(width: geo.size.width * paperwork.completionRate, height: 8)
                        }
                    }.frame(height: 8)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))

            Button(action: onUpload) {
                Label("Upload File", systemImage: "arrow.up.doc")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.5), lineWidth: 1)))
            }

            ForEach(paperwork.submissions ?? []) { submission in
                SubmissionRow(submission: submission)
                    .contextMenu {
                        if submission.status == .submitted {
                            Button { viewModel.verifySubmission(submission, verifiedByName: "Coach", context: modelContext) } label: { Label("Verify", systemImage: "checkmark.circle") }
                            Button { viewModel.rejectSubmission(submission, reason: "Incomplete", context: modelContext) } label: { Label("Reject", systemImage: "xmark.circle") }
                        }
                    }
            }
        }
    }
}

// MARK: - File Upload View
struct FileUploadView: View {
    let paperwork: PaperworkRequirement
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMemberName = ""
    @State private var documentData: Data? = nil
    @State private var documentFileName = ""
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                VStack(spacing: 16) {
                    Text("Upload File: \(paperwork.title)").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                    GlassTextField(title: "Player/Member Name", text: $selectedMemberName, placeholder: "Name")
                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: documentData != nil ? "checkmark.circle.fill" : "doc.badge.plus")
                                .foregroundColor(documentData != nil ? .green : .blue)
                            Text(documentData != nil ? documentFileName : "Choose File")
                                .foregroundColor(documentData != nil ? .green : .blue)
                        }
                        .padding().frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.5), lineWidth: 1))
                    }
                    .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .image, .text, .plainText], allowsMultipleSelection: false) { result in
                        if case .success(let urls) = result, let url = urls.first {
                            documentFileName = url.lastPathComponent
                            documentData = try? Data(contentsOf: url)
                        }
                    }

                    Button {
                        guard let data = documentData, !selectedMemberName.isEmpty else { return }
                        let submission = PaperworkSubmission(memberName: selectedMemberName, status: .submitted)
                        submission.documentData = data
                        submission.documentFileName = documentFileName
                        submission.submittedAt = Date()
                        submission.requirement = paperwork
                        modelContext.insert(submission)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Text("Upload").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()))
                            .opacity(documentData == nil || selectedMemberName.isEmpty ? 0.5 : 1)
                    }
                    .disabled(documentData == nil || selectedMemberName.isEmpty)
                }
                .padding()
            }
            .navigationTitle("File Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
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
                    .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(.white)
                if let submitted = submission.submittedAt {
                    Text("Submitted: \(submitted.formatted())").font(.caption2).foregroundColor(.gray)
                }
            }
            Spacer()
            if submission.documentData != nil {
                Image(systemName: "doc.fill").foregroundColor(.blue).font(.caption)
            }
            Text(submission.statusDisplay)
                .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(submission.statusColor.opacity(0.3)))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1)))
    }
}