import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Create Team View

struct CreateTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TeamManagementViewModel

    @State private var teamName = ""
    @State private var shortName = ""
    @State private var levelRaw = PlayLevel.club.rawValue
    @State private var season = "2026"
    @State private var organizationName = ""
    @State private var homeCourt = ""
    @State private var logoItem: PhotosPickerItem?
    @State private var logoData: Data?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 20) {
                        PhotosPicker(selection: $logoItem, matching: .images) {
                            ZStack {
                                Circle().fill(NeonGlassStyle.glassBackground).frame(width: 90, height: 90)
                                    .overlay(Circle().stroke(NeonGlassStyle.neonGradient(), lineWidth: 2))
                                if let logoData, let uiImage = UIImage(data: logoData) {
                                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(Circle())
                                } else {
                                    VStack(spacing: 4) {
                                        Image(systemName: "volleyball.fill").font(.title).foregroundColor(.pink)
                                        Text("Add Logo").font(.caption2).foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .onChange(of: logoItem) { _, newItem in
                            Task { if let data = try? await newItem?.loadTransferable(type: Data.self) { logoData = data } }
                        }

                        GlassTextField(title: "Team Name", text: $teamName, placeholder: "Enter team name")
                        GlassTextField(title: "Short Name", text: $shortName, placeholder: "e.g. VBT")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Level of Play").font(.caption).foregroundColor(.gray)
                            Picker("Level", selection: $levelRaw) {
                                ForEach(PlayLevel.allCases, id: \.rawValue) { level in
                                    Label(level.rawValue, systemImage: level.iconName).tag(level.rawValue)
                                }
                            }
                            .pickerStyle(.menu).foregroundColor(.white).padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                        }

                        GlassTextField(title: "Season", text: $season, placeholder: "e.g. 2026")
                        GlassTextField(title: "Organization", text: $organizationName, placeholder: "Club or school name")
                        GlassTextField(title: "Home Court", text: $homeCourt, placeholder: "Gym or facility name")

                        Button(action: createTeam) {
                            HStack { Image(systemName: "plus.circle.fill"); Text("Create Team").font(.system(size: 16, weight: .bold, design: .rounded)) }
                                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()).opacity(teamName.isEmpty ? 0.5 : 1.0))
                        }
                        .disabled(teamName.isEmpty)
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Create Team").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func createTeam() {
        let team = TeamModel(name: teamName, shortName: shortName, level: PlayLevel(rawValue: levelRaw) ?? .club,
                             season: season, organizationName: organizationName, homeCourt: homeCourt)
        team.logoData = logoData
        viewModel.createTeam(team, context: modelContext)
        dismiss()
    }
}

// MARK: - Edit Team View

struct EditTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TeamManagementViewModel
    let team: TeamModel

    @State private var teamName: String
    @State private var shortName: String
    @State private var levelRaw: String
    @State private var season: String
    @State private var organizationName: String
    @State private var homeCourt: String
    @State private var logoItem: PhotosPickerItem?
    @State private var logoData: Data?
    @State private var showDeleteAlert = false

    init(viewModel: TeamManagementViewModel, team: TeamModel) {
        self.viewModel = viewModel; self.team = team
        _teamName = State(initialValue: team.name); _shortName = State(initialValue: team.shortName)
        _levelRaw = State(initialValue: team.levelRaw); _season = State(initialValue: team.season)
        _organizationName = State(initialValue: team.organizationName); _homeCourt = State(initialValue: team.homeCourt)
        _logoData = State(initialValue: team.logoData)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 20) {
                        PhotosPicker(selection: $logoItem, matching: .images) {
                            ZStack {
                                Circle().fill(NeonGlassStyle.glassBackground).frame(width: 90, height: 90)
                                    .overlay(Circle().stroke(NeonGlassStyle.neonGradient(), lineWidth: 2))
                                if let logoData, let uiImage = UIImage(data: logoData) {
                                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(Circle())
                                } else {
                                    Image(systemName: "volleyball.fill").font(.title).foregroundColor(.pink)
                                }
                            }
                        }
                        .onChange(of: logoItem) { _, newItem in
                            Task { if let data = try? await newItem?.loadTransferable(type: Data.self) { logoData = data } }
                        }

                        GlassTextField(title: "Team Name", text: $teamName, placeholder: "Enter team name")
                        GlassTextField(title: "Short Name", text: $shortName, placeholder: "e.g. VBT")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Level of Play").font(.caption).foregroundColor(.gray)
                            Picker("Level", selection: $levelRaw) {
                                ForEach(PlayLevel.allCases, id: \.rawValue) { level in Text(level.rawValue).tag(level.rawValue) }
                            }
                            .pickerStyle(.menu).foregroundColor(.white).padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                        }

                        GlassTextField(title: "Season", text: $season, placeholder: "e.g. 2026")
                        GlassTextField(title: "Organization", text: $organizationName, placeholder: "Club or school name")
                        GlassTextField(title: "Home Court", text: $homeCourt, placeholder: "Gym or facility name")

                        Button(action: saveTeam) {
                            Text("Save Changes").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 2))
                        }
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete Team", systemImage: "trash").font(.caption).foregroundColor(.red)
                        }.padding(.top)
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Edit Team").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Delete Team?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { viewModel.deleteTeam(team, context: modelContext); dismiss() }
            } message: { Text("This will permanently delete the team and all associated data.") }
        }
    }

    private func saveTeam() {
        team.name = teamName; team.shortName = shortName; team.levelRaw = levelRaw
        team.season = season; team.organizationName = organizationName; team.homeCourt = homeCourt
        team.logoData = logoData
        viewModel.updateTeam(team, context: modelContext)
        dismiss()
    }
}

// MARK: - Create Member View

struct CreateMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TeamManagementViewModel
    let team: TeamModel

    @State private var firstName = ""; @State private var lastName = ""
    @State private var email = ""; @State private var phone = ""
    @State private var roleRaw = UserRole.player.rawValue
    @State private var jerseyNumber = 0; @State private var positionRaw = PlayerPosition.unknown.rawValue
    @State private var heightFeet = 5; @State private var heightInches = 0
    @State private var emergencyContact = ""; @State private var emergencyPhone = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 16) {
                        GlassTextField(title: "First Name", text: $firstName, placeholder: "First name")
                        GlassTextField(title: "Last Name", text: $lastName, placeholder: "Last name")
                        GlassTextField(title: "Email", text: $email, placeholder: "email@example.com").keyboardType(.emailAddress)
                        GlassTextField(title: "Phone", text: $phone, placeholder: "(555) 555-5555").keyboardType(.phonePad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Role").font(.caption).foregroundColor(.gray)
                            Picker("Role", selection: $roleRaw) {
                                ForEach(UserRole.allCases, id: \.rawValue) { role in Text(role.rawValue).tag(role.rawValue) }
                            }
                            .pickerStyle(.segmented)
                        }

                        if roleRaw == UserRole.player.rawValue {
                            HStack {
                                Text("Jersey #:").font(.caption).foregroundColor(.gray)
                                TextField("#", value: $jerseyNumber, format: .number).keyboardType(.numberPad)
                                    .foregroundColor(.white).frame(width: 60).padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))
                                Picker("Position", selection: $positionRaw) {
                                    ForEach(PlayerPosition.allCases, id: \.rawValue) { pos in Text(pos.rawValue).tag(pos.rawValue) }
                                }
                                .pickerStyle(.menu).foregroundColor(.white)
                            }
                            HStack {
                                Text("Height:").font(.caption).foregroundColor(.gray)
                                Picker("", selection: $heightFeet) { ForEach(4...7, id: \.self) { f in Text("\(f)'").tag(f) } }
                                Picker("", selection: $heightInches) { ForEach(0...11, id: \.self) { i in Text("\(i)\"").tag(i) } }
                            }
                            GlassTextField(title: "Emergency Contact", text: $emergencyContact, placeholder: "Contact name")
                            GlassTextField(title: "Emergency Phone", text: $emergencyPhone, placeholder: "(555) 555-5555").keyboardType(.phonePad)
                        }

                        Button(action: createMember) {
                            Text("Add to Team").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient())
                                    .opacity(firstName.isEmpty || lastName.isEmpty ? 0.5 : 1.0))
                        }.disabled(firstName.isEmpty || lastName.isEmpty)
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Add Member").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func createMember() {
        let member = TeamMember(firstName: firstName, lastName: lastName, email: email, phone: phone,
                                role: UserRole(rawValue: roleRaw) ?? .player,
                                jerseyNumber: jerseyNumber, position: PlayerPosition(rawValue: positionRaw) ?? .unknown,
                                heightFeet: heightFeet, heightInches: heightInches)
        member.emergencyContact = emergencyContact
        member.emergencyPhone = emergencyPhone
        viewModel.addMember(member, to: team, context: modelContext)
        dismiss()
    }
}

// MARK: - Edit Member View

struct EditMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TeamManagementViewModel
    let member: TeamMember

    @State private var firstName: String; @State private var lastName: String
    @State private var email: String; @State private var phone: String
    @State private var jerseyNumber: Int; @State private var positionRaw: String
    @State private var rating: Double; @State private var medicalNotes: String
    @State private var showRemoveAlert = false

    init(viewModel: TeamManagementViewModel, member: TeamMember) {
        self.viewModel = viewModel; self.member = member
        _firstName = State(initialValue: member.firstName); _lastName = State(initialValue: member.lastName)
        _email = State(initialValue: member.email); _phone = State(initialValue: member.phone)
        _jerseyNumber = State(initialValue: member.jerseyNumber); _positionRaw = State(initialValue: member.positionRaw)
        _rating = State(initialValue: member.rating); _medicalNotes = State(initialValue: member.medicalNotes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 16) {
                        GlassTextField(title: "First Name", text: $firstName, placeholder: "First name")
                        GlassTextField(title: "Last Name", text: $lastName, placeholder: "Last name")
                        GlassTextField(title: "Email", text: $email, placeholder: "email@example.com")
                        GlassTextField(title: "Phone", text: $phone, placeholder: "(555) 555-5555")

                        HStack {
                            Text("Jersey #:").font(.caption).foregroundColor(.gray)
                            TextField("#", value: $jerseyNumber, format: .number).keyboardType(.numberPad)
                                .foregroundColor(.white).padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))
                            Picker("Position", selection: $positionRaw) {
                                ForEach(PlayerPosition.allCases, id: \.rawValue) { pos in Text(pos.rawValue).tag(pos.rawValue) }
                            }.pickerStyle(.menu).foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rating: \(String(format: "%.1f", rating))").font(.caption).foregroundColor(.gray)
                            Slider(value: $rating, in: 0...10, step: 0.5).tint(.orange)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Medical Notes").font(.caption).foregroundColor(.gray)
                            TextEditor(text: $medicalNotes).frame(height: 80).foregroundColor(.white).padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5))).scrollContentBackground(.hidden)
                        }
                        Button(action: saveMember) {
                            Text("Save Changes").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 2))
                        }
                        Button(action: { showRemoveAlert = true }) {
                            Label("Remove Member", systemImage: "person.badge.minus").font(.caption).foregroundColor(.red)
                        }
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Edit Member").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Remove Member?", isPresented: $showRemoveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) { viewModel.removeMember(member, context: modelContext); dismiss() }
            } message: { Text("This member will be archived and can be restored later.") }
        }
    }

    private func saveMember() {
        member.firstName = firstName; member.lastName = lastName; member.email = email; member.phone = phone
        member.jerseyNumber = jerseyNumber; member.positionRaw = positionRaw; member.rating = rating
        member.medicalNotes = medicalNotes
        viewModel.updateMember(member, context: modelContext)
        dismiss()
    }
}

// MARK: - Create Match View (Schedule Match)

struct CreateMatchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TeamManagementViewModel
    let team: TeamModel

    @State private var opponentName = ""; @State private var matchTypeRaw = MatchType.regular.rawValue
    @State private var location = ""; @State private var isHomeGame = true
    @State private var matchDate = Date(); @State private var matchTime = Date()
    @State private var tournamentName = ""; @State private var notes = ""

    var combinedDate: Date {
        let cal = Calendar.current
        let dateComponents = cal.dateComponents([.year, .month, .day], from: matchDate)
        let timeComponents = cal.dateComponents([.hour, .minute], from: matchTime)
        return cal.date(from: DateComponents(year: dateComponents.year, month: dateComponents.month, day: dateComponents.day,
                                              hour: timeComponents.hour, minute: timeComponents.minute)) ?? matchDate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 16) {
                        GlassTextField(title: "Opponent", text: $opponentName, placeholder: "Team name")
                        GlassTextField(title: "Location", text: $location, placeholder: "Venue or school name")

                        Toggle("Home Game", isOn: $isHomeGame).foregroundColor(.white).tint(.pink)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Match Type").font(.caption).foregroundColor(.gray)
                            Picker("Type", selection: $matchTypeRaw) {
                                ForEach(MatchType.allCases, id: \.rawValue) { type in Text(type.rawValue).tag(type.rawValue) }
                            }.pickerStyle(.segmented)
                        }

                        if matchTypeRaw == MatchType.tournament.rawValue {
                            GlassTextField(title: "Tournament Name", text: $tournamentName, placeholder: "Tournament name")
                        }

                        DatePicker("Match Date", selection: $matchDate, displayedComponents: .date)
                            .foregroundColor(.white).colorScheme(.dark)
                            .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.4)))
                        DatePicker("Match Time", selection: $matchTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(.white).colorScheme(.dark)
                            .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.4)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes").font(.caption).foregroundColor(.gray)
                            TextEditor(text: $notes).frame(height: 60).foregroundColor(.white).padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5))).scrollContentBackground(.hidden)
                        }

                        Button(action: createMatch) {
                            Text("Schedule Match").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()))
                        }
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("New Match").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func createMatch() {
        let match = MatchModel(opponentName: opponentName, matchType: MatchType(rawValue: matchTypeRaw) ?? .regular,
                               location: location, matchDate: combinedDate, isHomeGame: isHomeGame,
                               homeTeamName: team.name, awayTeamName: opponentName, notes: notes, tournamentName: tournamentName)
        match.isLive = false; match.isCompleted = false
        viewModel.createMatch(match, for: team, context: modelContext)
        dismiss()
    }
}

// MARK: - Create Event View

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TeamManagementViewModel
    let team: TeamModel

    @State private var title = ""; @State private var eventTypeRaw = EventType.practice.rawValue
    @State private var startDate = Date(); @State private var endDate = Date().addingTimeInterval(7200)
    @State private var location = ""; @State private var notes = ""
    @State private var requiresRSVP = false; @State private var notificationMinutes = 30

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 16) {
                        GlassTextField(title: "Event Title", text: $title, placeholder: "Practice, Game, etc.")
                        GlassTextField(title: "Location", text: $location, placeholder: "Gym or facility")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Event Type").font(.caption).foregroundColor(.gray)
                            Picker("Type", selection: $eventTypeRaw) {
                                ForEach(EventType.allCases, id: \.rawValue) { type in
                                    Label(type.rawValue, systemImage: type.iconName).tag(type.rawValue)
                                }
                            }
                            .pickerStyle(.menu).foregroundColor(.white).padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                        }

                        DatePicker("Start", selection: $startDate).foregroundColor(.white).colorScheme(.dark)
                            .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.4)))
                        DatePicker("End", selection: $endDate).foregroundColor(.white).colorScheme(.dark)
                            .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.4)))

                        Toggle("Requires RSVP", isOn: $requiresRSVP).foregroundColor(.white).tint(.pink)
                        if requiresRSVP {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reminder before (minutes)").font(.caption).foregroundColor(.gray)
                                Picker("", selection: $notificationMinutes) {
                                    Text("At time").tag(0); Text("15 min").tag(15); Text("30 min").tag(30)
                                    Text("1 hour").tag(60); Text("2 hours").tag(120); Text("1 day").tag(1440)
                                }.pickerStyle(.menu).foregroundColor(.white)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes").font(.caption).foregroundColor(.gray)
                            TextEditor(text: $notes).frame(height: 60).foregroundColor(.white).padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5))).scrollContentBackground(.hidden)
                        }

                        Button(action: createEvent) {
                            Text("Create Event").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()).opacity(title.isEmpty ? 0.5 : 1.0))
                        }.disabled(title.isEmpty)
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("New Event").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func createEvent() {
        let event = CalendarEvent(title: title, eventType: EventType(rawValue: eventTypeRaw) ?? .practice,
                                  startDate: startDate, endDate: endDate, location: location, notes: notes,
                                  requiresRSVP: requiresRSVP, notificationMinutesBefore: notificationMinutes)
        viewModel.createEvent(event, for: team, context: modelContext)
        dismiss()
    }
}

// MARK: - Create Paperwork View

struct CreatePaperworkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: TeamManagementViewModel
    let team: TeamModel

    @State private var title = ""; @State private var typeRaw = PaperworkType.custom.rawValue
    @State private var descriptionText = ""; @State private var isRequired = true
    @State private var dueDate = Date().addingTimeInterval(86400 * 14)
    @State private var autoReminder = true; @State private var reminderDays = 3

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                ScrollView {
                    VStack(spacing: 16) {
                        GlassTextField(title: "Form Name", text: $title, placeholder: "e.g. Team Waiver")
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type").font(.caption).foregroundColor(.gray)
                            Picker("Type", selection: $typeRaw) {
                                ForEach(PaperworkType.allCases, id: \.rawValue) { t in Text(t.rawValue).tag(t.rawValue) }
                            }
                            .pickerStyle(.menu).foregroundColor(.white).padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description").font(.caption).foregroundColor(.gray)
                            TextEditor(text: $descriptionText).frame(height: 80).foregroundColor(.white).padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5))).scrollContentBackground(.hidden)
                        }
                        Toggle("Required", isOn: $isRequired).foregroundColor(.white).tint(.pink)
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                            .foregroundColor(.white).colorScheme(.dark)
                            .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.4)))
                        Toggle("Auto Reminder", isOn: $autoReminder).foregroundColor(.white).tint(.pink)
                        if autoReminder {
                            HStack {
                                Text("Remind").font(.caption).foregroundColor(.gray)
                                Picker("", selection: $reminderDays) {
                                    ForEach(1...14, id: \.self) { d in Text("\(d) days before").tag(d) }
                                }.pickerStyle(.menu).foregroundColor(.white)
                            }
                        }
                        Button(action: createPaperwork) {
                            Text("Create Form").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()).opacity(title.isEmpty ? 0.5 : 1))
                        }.disabled(title.isEmpty)
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("New Paperwork").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func createPaperwork() {
        let paperwork = PaperworkRequirement(title: title, type: PaperworkType(rawValue: typeRaw) ?? .custom,
                                             descriptionText: descriptionText, isRequired: isRequired, dueDate: dueDate,
                                             autoReminderEnabled: autoReminder, reminderDaysBefore: reminderDays)
        viewModel.createPaperwork(paperwork, for: team, context: modelContext)
        dismiss()
    }
}

// MARK: - Glass TextField

struct GlassTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
        }
    }
}