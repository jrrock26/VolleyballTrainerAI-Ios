import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Team Info Detail View

struct TeamInfoDetailView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatCard(title: "Players", value: "\(team.players.count)", icon: "person.fill", color: .pink)
                StatCard(title: "Coaches", value: "\(team.coaches.count)", icon: "person.2.fill", color: .blue)
                StatCard(title: "Record", value: team.activeSeason?.recordString ?? "0-0", icon: "trophy.fill", color: .orange)
                StatCard(title: "Events", value: "\(team.events?.count ?? 0)", icon: "calendar", color: .green)
            }

            if let season = team.activeSeason {
                VStack(spacing: 8) {
                    HStack {
                        Text("Season: \(season.name)").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)
                        Spacer()
                        Text("\(season.setRecordString) sets").font(.caption).foregroundColor(.gray)
                    }
                    HStack {
                        Label("+\(season.pointDifferential) pt diff", systemImage: "arrow.up.forward").font(.caption).foregroundColor(.green)
                        Spacer()
                        Label("\(season.winCount) W - \(season.lossCount) L", systemImage: "chart.bar").font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Matches").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)
                let recentMatches = (team.matches ?? []).sorted { $0.matchDate > $1.matchDate }.prefix(3)
                if recentMatches.isEmpty {
                    Text("No matches yet.").font(.caption).foregroundColor(.gray).padding(.vertical, 8)
                } else {
                    ForEach(Array(recentMatches)) { match in MatchMiniRow(match: match) }
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Invite Members").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)
                    Spacer()
                }
                HStack {
                    Text(team.joinCode).font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(.blue).shadow(color: .blue.opacity(0.5), radius: 4)
                    Spacer()
                    Button(action: { UIPasteboard.general.string = team.joinCode }) {
                        Label("Copy", systemImage: "doc.on.doc").font(.caption).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1))
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))
        }
    }
}

// MARK: - Match Mini Row

struct MatchMiniRow: View {
    let match: MatchModel
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(match.opponentName.isEmpty ? "TBD" : match.opponentName).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white)
                Text(match.matchDate, style: .date).font(.caption2).foregroundColor(.gray)
            }
            Spacer()
            Text(match.scoreDisplay).font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(match.isCompleted ? (match.winner == "home" ? .green : .red) : .orange)
            Image(systemName: match.matchType == .tournament ? "flag.2.crossed" : "sportscourt").font(.caption).foregroundColor(.blue)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1)))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(title).font(.system(size: 10, design: .rounded)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1)))
    }
}

// MARK: - Roster List View (Coaches, Players, Staff)

struct RosterListView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showContactInfo = false

    var body: some View {
        VStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search roster...", text: $viewModel.searchText).foregroundColor(.white)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))

            // Coaches/Staff section
            let coaches = team.members?.filter { ($0.role != .player && $0.role != .parent) && !$0.isArchived } ?? []
            let filteredCoaches = viewModel.searchText.isEmpty ? coaches : coaches.filter { $0.fullName.localizedCaseInsensitiveContains(viewModel.searchText) }
            if !filteredCoaches.isEmpty {
                sectionHeader("Coaching Staff", count: filteredCoaches.count)
                ForEach(filteredCoaches) { member in
                    MemberRow(member: member)
                        .onTapGesture { viewModel.selectedMember = member; viewModel.isEditingMember = true }
                }
            }

            // Players
            let players = team.players.filter {
                viewModel.searchText.isEmpty || $0.fullName.localizedCaseInsensitiveContains(viewModel.searchText) || String($0.jerseyNumber).contains(viewModel.searchText)
            }
            sectionHeader("Players", count: players.count)
            if players.isEmpty {
                Text("No players found").font(.caption).foregroundColor(.gray).padding()
            } else {
                ForEach(players) { player in
                    MemberRow(member: player)
                        .onTapGesture { viewModel.selectedMember = player; viewModel.isEditingMember = true }
                }
            }

            // Parents contact list (not on roster, just contacts)
            let parents = team.members?.filter { $0.role == .parent && !$0.isArchived } ?? []
            let filteredParents = viewModel.searchText.isEmpty ? parents : parents.filter { $0.fullName.localizedCaseInsensitiveContains(viewModel.searchText) }
            if !filteredParents.isEmpty {
                sectionHeader("Parent Contacts", count: filteredParents.count)
                ForEach(filteredParents) { parent in
                    MemberRow(member: parent)
                        .onTapGesture { viewModel.selectedMember = parent; viewModel.isEditingMember = true }
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditingMember) {
            if let member = viewModel.selectedMember {
                EditMemberView(viewModel: viewModel, member: member)
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.gray)
            Text("(\(count))").font(.caption).foregroundColor(.gray.opacity(0.7))
            Spacer()
        }.padding(.top, 6)
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: TeamMember
    @State private var showContact = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.black.opacity(0.7)).frame(width: 40, height: 40)
                    .overlay(Circle().stroke(member.role == .player ? Color.pink.opacity(0.5) : (member.role == .parent ? Color.green.opacity(0.5) : Color.blue.opacity(0.5)), lineWidth: 1.5))
                if let photoData = member.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 34, height: 34).clipShape(Circle())
                } else {
                    Text(member.firstName.prefix(1) + member.lastName.prefix(1)).font(.caption2).foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(member.fullName).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                if member.role == .player {
                    HStack(spacing: 6) {
                        Text("#\(member.jerseyNumber)").font(.system(size: 10, design: .monospaced)).foregroundColor(.pink)
                        Text(member.position.rawValue).font(.caption2).foregroundColor(.gray)
                        Text(member.displayHeight).font(.caption2).foregroundColor(.gray)
                    }
                } else if member.role == .parent {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill").font(.caption2).foregroundColor(.gray)
                        Text(member.email.isEmpty ? "No email" : member.email).font(.caption2).foregroundColor(.gray).lineLimit(1)
                    }
                } else {
                    Text(member.role.rawValue).font(.caption2).foregroundColor(.blue)
                }
            }
            Spacer()
            if member.role == .player {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", member.rating)).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                    Text("rating").font(.system(size: 8)).foregroundColor(.gray)
                }
            }
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.gray)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1)))
    }
}

// MARK: - Match List View

struct MatchListView: View {
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showScheduleSheet = false
    @State private var selectedMatchForSchedule: MatchModel?

    var body: some View {
        VStack(spacing: 12) {
            let matches = (team.matches ?? []).sorted { $0.matchDate > $1.matchDate }

            if matches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy").font(.largeTitle).foregroundColor(.gray)
                    Text("No Matches Yet").font(.headline).foregroundColor(.gray)
                    Text("Create a new match or schedule one from the quick actions above.").font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                }.padding(.vertical, 40)
            } else {
                ForEach(matches) { match in
                    MatchRow(match: match)
                        .onTapGesture {
                            viewModel.selectedMatch = match
                            // If scheduled match, offer to go live
                            if !match.isCompleted && !match.isLive {
                                selectedMatchForSchedule = match
                                showScheduleSheet = true
                            }
                        }
                        .contextMenu {
                            if !match.isCompleted && !match.isLive {
                                Button {
                                    viewModel.scoringEngine.startMatch()
                                    viewModel.showLiveScoring = true
                                } label: { Label("Go Live", systemImage: "play.fill") }
                            }
                            if match.isCompleted {
                                Button { viewModel.selectedMatch = match } label: { Label("View Stats", systemImage: "chart.bar") }
                            }
                            Button(role: .destructive) { viewModel.deleteMatch(match, context: modelContext) } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
        }
        .confirmationDialog("Match Options", isPresented: $showScheduleSheet, presenting: selectedMatchForSchedule) { match in
            Button("Go Live Now") {
                viewModel.scoringEngine.startMatch()
                viewModel.showLiveScoring = true
            }
            Button("Edit Schedule") {
                viewModel.showCreateMatch = true
            }
            Button("Cancel", role: .cancel) { }
        } message: { match in
            Text("\(match.displayTitle)\nScheduled: \(match.matchDate.formatted())")
        }
    }
}

// MARK: - Match Row

struct MatchRow: View {
    let match: MatchModel
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(match.opponentName.isEmpty ? "TBD" : "vs \(match.opponentName)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: match.isHomeGame ? "house.fill" : "airplane.departure").font(.caption2)
                    Text(match.matchDate, style: .date).font(.caption2)
                    Text(match.matchDate, style: .time).font(.caption2)
                }.foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(match.scoreDisplay).font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(match.isCompleted ? (match.winner == "home" ? .green : .red) : .orange)
                HStack(spacing: 2) {
                    Circle().fill(match.isLive ? Color.green : (match.isCompleted ? Color.gray : Color.orange)).frame(width: 6, height: 6)
                    Text(match.isLive ? "LIVE" : (match.isCompleted ? "Final" : "Scheduled"))
                        .font(.system(size: 10, design: .rounded)).foregroundColor(match.isLive ? .green : .gray)
                }
            }
            Text(match.matchType == .tournament ? "🏆" : "").font(.caption)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(match.isLive ? Color.green.opacity(0.7) : Color.white.opacity(0.15), lineWidth: match.isLive ? 2 : 1)))
        .overlay(Group {
            if match.isLive { RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.4), lineWidth: 1).blur(radius: 4) }
        })
    }
}

// MARK: - Team Stats View

struct TeamStatsView: View {
    let team: TeamModel
    @State private var selectedPlayer: TeamMember?
    @State private var showPlayerStats = false

    var body: some View {
        VStack(spacing: 14) {
            if let season = team.activeSeason {
                HStack(spacing: 12) {
                    StatCard(title: "Wins", value: "\(season.winCount)", icon: "checkmark.circle.fill", color: .green)
                    StatCard(title: "Losses", value: "\(season.lossCount)", icon: "xmark.circle.fill", color: .red)
                    StatCard(title: "Win %", value: String(format: "%.0f%%", winPercentage(season)), icon: "percent", color: .blue)
                    StatCard(title: "Set Diff", value: "\(season.setWins - season.setLosses)", icon: "arrow.up.forward", color: .orange)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("Points Scored").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Text("\(season.totalPointsScored)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.green)
                    }
                    HStack {
                        Text("Points Allowed").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Text("\(season.totalPointsAllowed)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.red)
                    }
                    Divider().background(Color.white.opacity(0.2))
                    HStack {
                        Text("Differential").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Text("\(season.pointDifferential > 0 ? "+" : "")\(season.pointDifferential)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(season.pointDifferential >= 0 ? .green : .red)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))
            }

            // Player Stats Leaderboard
            VStack(alignment: .leading, spacing: 10) {
                Text("Player Stats").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.white)

                ForEach(team.players.sorted(by: { $0.rating > $1.rating }).prefix(10)) { player in
                    Button {
                        selectedPlayer = player
                        showPlayerStats = true
                    } label: {
                        HStack {
                            Text("#\(player.jerseyNumber)")
                                .font(.system(size: 12, design: .monospaced)).foregroundColor(.pink).frame(width: 30)
                            Text(player.fullName).font(.system(size: 14, design: .rounded)).foregroundColor(.white)
                            Spacer()
                            // Show aggregated stats for player
                            if let stats = player.playerStats, !stats.isEmpty {
                                let agg = StatsEngine.aggregatePlayerStats(Array(stats))
                                Text("K:\(agg.kills) H%:\(String(format: "%.3f", agg.hittingPercentage))")
                                    .font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                            }
                            Text(String(format: "%.1f", player.rating))
                                .font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                        }.padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))
        }
        .sheet(isPresented: $showPlayerStats) {
            if let player = selectedPlayer {
                PlayerStatsDetailView(player: player)
            }
        }
    }

    private func winPercentage(_ season: TeamSeason) -> Double {
        guard season.winCount + season.lossCount > 0 else { return 0 }
        return Double(season.winCount) / Double(season.winCount + season.lossCount) * 100
    }
}

// MARK: - Player Stats Detail View

struct PlayerStatsDetailView: View {
    let player: TeamMember
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))

                ScrollView {
                    VStack(spacing: 16) {
                        // Player header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(Color.black.opacity(0.7)).frame(width: 70, height: 70)
                                    .overlay(Circle().stroke(NeonGlassStyle.neonGradient(), lineWidth: 2))
                                if let photo = player.photoData, let img = UIImage(data: photo) {
                                    Image(uiImage: img).resizable().scaledToFill().frame(width: 60, height: 60).clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill").font(.title).foregroundColor(.pink)
                                }
                            }
                            Text(player.fullName).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)
                            HStack(spacing: 8) {
                                Text("#\(player.jerseyNumber)").font(.system(size: 14, design: .monospaced)).foregroundColor(.pink)
                                Text(player.position.rawValue).font(.caption).foregroundColor(.gray)
                                Text(player.displayHeight).font(.caption).foregroundColor(.gray)
                            }
                            Text("Rating: \(String(format: "%.1f", player.rating))")
                                .font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.55))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1.5)))

                        // Aggregated stats
                        if let allStats = player.playerStats, !allStats.isEmpty {
                            let agg = StatsEngine.aggregatePlayerStats(Array(allStats))
                            VStack(spacing: 10) {
                                Text("Cumulative Stats").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                                    statGridItem("Kills", "\(agg.kills)", .pink)
                                    statGridItem("Attacks", "\(agg.attackAttempts)", .pink)
                                    statGridItem("Hit %", String(format: "%.3f", agg.hittingPercentage), .pink)
                                    statGridItem("Aces", "\(agg.aces)", .yellow)
                                    statGridItem("Serves", "\(agg.serveAttempts)", .yellow)
                                    statGridItem("Blocks", "\(agg.totalBlocks)", .purple)
                                    statGridItem("Digs", "\(agg.digs)", .green)
                                    statGridItem("Assists", "\(agg.assists)", .cyan)
                                    statGridItem("Points", "\(agg.totalPoints)", .orange)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))
                        } else {
                            Text("No stats recorded yet").font(.caption).foregroundColor(.gray).padding(.vertical, 20)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Player Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    @ViewBuilder
    private func statGridItem(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(color)
            Text(title).font(.system(size: 10)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.4)))
    }
}