import SwiftUI
import SwiftData

// MARK: - Team Management Hub (Main Navigation Entry)

struct TeamManagementHubView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TeamManagementViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.7))

            VStack(spacing: 0) {
                // Header with safe area padding
                headerView

                if viewModel.teams.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let team = viewModel.selectedTeam {
                                teamDetailSection(team)
                            } else {
                                teamListView
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .padding(.top, 60)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationBarHidden(true)
        .onAppear { viewModel.fetchTeams(context: modelContext) }
        .sheet(isPresented: $viewModel.isCreatingTeam) { CreateTeamView(viewModel: viewModel) }
        .fullScreenCover(isPresented: $viewModel.showLiveScoring) {
            if let team = viewModel.selectedTeam {
                LiveScoringView(engine: viewModel.scoringEngine, team: team, viewModel: viewModel)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TEAM MANAGEMENT")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .pink.opacity(0.5), radius: 6)

                if let team = viewModel.selectedTeam {
                    Button(action: { viewModel.selectedTeam = nil }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.caption)
                            Text("All Teams").font(.caption)
                        }.foregroundColor(.blue)
                    }
                }
            }
            Spacer()
            HStack(spacing: 12) {
                if viewModel.isOffline {
                    Image(systemName: "wifi.slash").foregroundColor(.orange).font(.caption)
                }
                Button(action: { viewModel.isCreatingTeam = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(LinearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Color.black.opacity(0.9))
        .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.15)), alignment: .bottom)
        .zIndex(1)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 120)
            Image(systemName: "volleyball.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .pink.opacity(0.5), radius: 20)
            Text("No Teams Yet")
                .font(.system(size: 27, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text("Create your first team to get started with\nteam management, live scoring, and more.")
                .font(.system(size: 15, design: .rounded)).foregroundColor(.gray).multilineTextAlignment(.center)
            Button(action: { viewModel.isCreatingTeam = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill"); Text("Create Team")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white).padding(.horizontal, 32).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.glassBackground)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 2)))
            }
            Spacer()
        }.padding()
    }

    // MARK: - Team List
    private var teamListView: some View {
        VStack(spacing: 16) {
            Text("Your Teams").font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7)).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
            ForEach(viewModel.teams.filter { !$0.isArchived }) { team in
                TeamCardView(team: team) { withAnimation { viewModel.selectedTeam = team } }
            }
            if !viewModel.teams.filter({ $0.isArchived }).isEmpty {
                DisclosureGroup {
                    ForEach(viewModel.teams.filter { $0.isArchived }) { team in
                        TeamCardView(team: team, isArchived: true) { withAnimation { viewModel.selectedTeam = team } }
                    }
                } label: { Text("Archived Teams").font(.system(size: 14, design: .rounded)).foregroundColor(.gray) }
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Team Detail
    private func teamDetailSection(_ team: TeamModel) -> some View {
        VStack(spacing: 16) {
            TeamInfoCard(team: team, viewModel: viewModel)
            quickActionsRow(team: team)
            tabPicker
            tabContent(team: team)
        }
    }

    // MARK: - Quick Actions
    private func quickActionsRow(team: TeamModel) -> some View {
        HStack(spacing: 10) {
            QuickActionButton(title: "New Match", icon: "trophy.fill", color: .orange) {
                viewModel.showCreateMatch = true
            }
            QuickActionButton(title: "Schedule", icon: "calendar.badge.plus", color: .blue) {
                viewModel.showCreateEvent = true
            }
            QuickActionButton(title: "Add Player", icon: "person.badge.plus", color: .pink) {
                viewModel.isCreatingMember = true
            }
            QuickActionButton(title: "Paperwork", icon: "doc.badge.plus", color: .green) {
                viewModel.showCreatePaperwork = true
            }
        }
        .sheet(isPresented: $viewModel.showCreateMatch) { CreateMatchView(viewModel: viewModel, team: team) }
        .sheet(isPresented: $viewModel.showCreateEvent) { CreateEventView(viewModel: viewModel, team: team) }
        .sheet(isPresented: $viewModel.isCreatingMember) { CreateMemberView(viewModel: viewModel, team: team) }
        .sheet(isPresented: $viewModel.showCreatePaperwork) { CreatePaperworkView(viewModel: viewModel, team: team) }
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TeamTab.allCases, id: \.self) { tab in
                    TabPill(title: tab.rawValue, icon: tab.iconName, isSelected: viewModel.selectedTab == tab) {
                        withAnimation { viewModel.selectedTab = tab }
                    }
                }
            }.padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func tabContent(team: TeamModel) -> some View {
        switch viewModel.selectedTab {
        case .team: TeamInfoDetailView(team: team, viewModel: viewModel)
        case .roster: RosterListView(team: team, viewModel: viewModel)
        case .matches: MatchListView(team: team, viewModel: viewModel)
        case .stats: TeamStatsView(team: team)
        case .schedule: ScheduleView(team: team, viewModel: viewModel)
        case .chat: ChatListView(team: team, viewModel: viewModel)
        case .paperwork: PaperworkListView(team: team, viewModel: viewModel)
        }
    }
}

// MARK: - Team Card View
struct TeamCardView: View {
    let team: TeamModel
    var isArchived: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.black.opacity(0.7)).frame(width: 50, height: 50)
                        .overlay(Circle().stroke(NeonGlassStyle.neonGradient(startColor: .pink, endColor: .blue), lineWidth: 2))
                    if let logoData = team.logoData, let uiImage = UIImage(data: logoData) {
                        Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(Circle())
                    } else {
                        Image(systemName: team.level.iconName).font(.title2).foregroundColor(.pink)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                    HStack(spacing: 8) {
                        Label(team.level.rawValue, systemImage: team.level.iconName).font(.caption).foregroundColor(.blue)
                        Label(team.season, systemImage: "calendar").font(.caption).foregroundColor(.gray)
                    }
                    Text("\(team.players.count) players • \(team.coaches.count) coaches").font(.caption2).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.65))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(NeonGlassStyle.neonGradient(startColor: .pink.opacity(0.6), endColor: .blue.opacity(0.5)), lineWidth: 1.5)))
            .opacity(isArchived ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Team Info Card
struct TeamInfoCard: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.black.opacity(0.7)).frame(width: 56, height: 56)
                    .overlay(Circle().stroke(NeonGlassStyle.neonGradient(), lineWidth: 2))
                if let logoData = team.logoData, let uiImage = UIImage(data: logoData) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 46, height: 46).clipShape(Circle())
                } else {
                    Image(systemName: "volleyball.fill").font(.title2).foregroundColor(.pink)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(team.name).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text("\(team.level.rawValue) • \(team.season)").font(.caption).foregroundColor(.gray)
                Text("Join Code: \(team.joinCode)").font(.system(size: 12, design: .monospaced)).foregroundColor(.blue)
            }
            Spacer()
            Button(action: { viewModel.isEditingTeam = true }) {
                Image(systemName: "pencil.circle.fill").font(.title3).foregroundColor(.blue)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.65))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1.5)))
        .sheet(isPresented: $viewModel.isEditingTeam) { EditTeamView(viewModel: viewModel, team: team) }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    @State private var isPressed = false
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
                Text(title).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.5), lineWidth: 1)))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isPressed = true }.onEnded { _ in isPressed = false })
    }
}

// MARK: - Tab Pill
struct TabPill: View {
    let title: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption); Text(title).font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 20).fill(isSelected ? Color.pink.opacity(0.3) : Color.black.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.pink : Color.white.opacity(0.2), lineWidth: 1)))
        }
    }
}

#Preview {
    TeamManagementHubView().modelContainer(for: [TeamModel.self, TeamMember.self, MatchModel.self])
}