import SwiftUI
import SwiftData

// MARK: - Live Scoring View (GameChanger-Style)

struct LiveScoringView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var engine: LiveScoringEngine
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel

    @State private var showEndMatchAlert = false
    @State private var showMatchSummary = false
    @State private var selectedTab = 0
    @State private var selectedZone: String? = nil
    @State private var showPlayerAssignSheet = false
    @State private var assignSide: String = "home"
    @State private var assignPosition: String = "P1"
    @State private var showSubSheet = false
    @State private var subSide: String = "home"
    @State private var selectedPlayerForStat: UUID? = nil
    @State private var showPlayerStatPicker = false
    @State private var statSide: String = "home"

    enum LiveTab: String, CaseIterable {
        case score = "Score"
        case court = "Court"
        case stats = "Stats"
        case playbyplay = "Plays"
        var icon: String {
            switch self {
            case .score: return "hand.tap.fill"
            case .court: return "sportscourt.fill"
            case .stats: return "chart.bar.fill"
            case .playbyplay: return "list.bullet.rectangle"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.65))

            if engine.isMatchOver && showMatchSummary {
                matchSummaryView
            } else {
                VStack(spacing: 0) {
                    topBarView
                    scoreboardView

                    if !engine.isMatchOver {
                        actionTabBar
                        ScrollView {
                            VStack(spacing: 14) {
                                switch LiveTab.allCases[safe: selectedTab] ?? .court {
                                case .score: scoringActionsPanel
                                case .court: courtViewPanel
                                case .stats: statsPanel
                                case .playbyplay: playByPlayPanel
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
        }
        .alert("End Match?", isPresented: $showEndMatchAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Match", role: .destructive) {
                engine.isMatchOver = true
                showMatchSummary = true
            }
        } message: {
            Text("Current score: \(engine.homeSetsWon)-\(engine.awaySetsWon)")
        }
        .sheet(isPresented: $showPlayerAssignSheet) {
            playerAssignSheet
        }
        .sheet(isPresented: $showSubSheet) {
            substitutionSheet
        }
        .sheet(isPresented: $showPlayerStatPicker) {
            playerStatSheet
        }
    }

    // MARK: - Top Bar
    private var topBarView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("LIVE SCORING")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    if let start = engine.matchStartTime {
                        Text(timeElapsedString(from: start))
                            .font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Menu {
                Button { showEndMatchAlert = true } label: {
                    Label("End Match", systemImage: "stop.circle")
                }
                Button { engine.undoLastPoint() } label: {
                    Label("Undo Point", systemImage: "arrow.uturn.backward")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill").font(.title3).foregroundColor(.white)
            }
        }
        .padding(.horizontal).padding(.top, 12).padding(.bottom, 6)
        .background(Color.black.opacity(0.85))
    }

    // MARK: - Scoreboard
    private var scoreboardView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(spacing: 4) {
                    Text(team.shortName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.pink)
                    Text("\(engine.homeScore)")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .pink.opacity(0.5), radius: 10)
                    if engine.isServing == "home" {
                        HStack(spacing: 2) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("SERVING").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundColor(.green)
                        }
                    }
                    Text("Sets: \(engine.homeSetsWon)").font(.caption).foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 6) {
                    Text("VS").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.gray)
                    Text("Set \(engine.currentSet)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(.blue)
                    Text("Best of 5").font(.system(size: 9)).foregroundColor(.gray)
                    if engine.isTimeoutActive {
                        Text("TIMEOUT").font(.system(size: 10, weight: .bold)).foregroundColor(.orange)
                    }
                }
                .frame(width: 60)

                VStack(spacing: 4) {
                    Text("AWAY").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.blue)
                    Text("\(engine.awayScore)")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.5), radius: 10)
                    if engine.isServing == "away" {
                        HStack(spacing: 2) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("SERVING").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundColor(.green)
                        }
                    }
                    Text("Sets: \(engine.awaySetsWon)").font(.caption).foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            if !engine.setHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(engine.setHistory) { set in
                            HStack(spacing: 4) {
                                Text("S\(set.setNumber)").font(.caption2).foregroundColor(.gray)
                                Text("\(set.homeScore)-\(set.awayScore)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(set.winner == "home" ? .pink : .blue)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(set.winner == "home" ? Color.pink.opacity(0.5) : Color.blue.opacity(0.5), lineWidth: 1)))
                        }
                    }
                }.padding(.horizontal)
            }
        }
        .padding(.vertical, 10).padding(.horizontal)
        .background(RoundedRectangle(cornerRadius: 18)
            .fill(Color.black.opacity(0.65))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(NeonGlassStyle.neonGradient(), lineWidth: 2)))
        .padding(.horizontal, 10)
    }

    // MARK: - Tab Bar
    private var actionTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LiveTab.allCases.indices, id: \.self) { i in
                Button {
                    withAnimation { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: LiveTab.allCases[i].icon).font(.caption2)
                        Text(LiveTab.allCases[i].rawValue).font(.system(size: 10, design: .rounded))
                    }
                    .foregroundColor(selectedTab == i ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == i ? Color.pink.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.7))
    }

    // MARK: - Scoring Panel
    private var scoringActionsPanel: some View {
        VStack(spacing: 14) {
            // Quick point for HOME
            VStack(spacing: 8) {
                Text("HOME (\(team.shortName))").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.pink)
                HStack(spacing: 8) {
                    ScoreActionButton(title: "Kill", icon: "flame.fill", color: .pink) {
                        engine.awardPoint(to: "home", playerID: UUID(), eventType: "attack")
                    }
                    ScoreActionButton(title: "Ace", icon: "bolt.fill", color: .yellow) {
                        engine.awardAce(team: "home", playerID: UUID())
                    }
                    ScoreActionButton(title: "Block", icon: "hand.raised.fill", color: .purple) {
                        engine.awardPoint(to: "home", playerID: UUID(), eventType: "block")
                    }
                    ScoreActionButton(title: "+Err", icon: "xmark.circle.fill", color: .red) {
                        engine.recordError(team: "away", playerID: UUID(), errorType: "attack_error")
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pink.opacity(0.4), lineWidth: 1)))

            // Quick point for AWAY
            VStack(spacing: 8) {
                Text("AWAY").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.blue)
                HStack(spacing: 8) {
                    ScoreActionButton(title: "Kill", icon: "flame.fill", color: .blue) {
                        engine.awardPoint(to: "away", playerID: UUID(), eventType: "attack")
                    }
                    ScoreActionButton(title: "Ace", icon: "bolt.fill", color: .yellow) {
                        engine.awardAce(team: "away", playerID: UUID())
                    }
                    ScoreActionButton(title: "Block", icon: "hand.raised.fill", color: .purple) {
                        engine.awardPoint(to: "away", playerID: UUID(), eventType: "block")
                    }
                    ScoreActionButton(title: "+Err", icon: "xmark.circle.fill", color: .red) {
                        engine.recordError(team: "home", playerID: UUID(), errorType: "attack_error")
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.4), lineWidth: 1)))

            HStack(spacing: 10) {
                ScoreActionButton(title: "Timeout", icon: "timer", color: .orange) {
                    engine.callTimeout(for: "home")
                }
                ScoreActionButton(title: "Sub", icon: "arrow.triangle.swap", color: .green) {
                    subSide = "home"; showSubSheet = true
                }
                ScoreActionButton(title: "Undo", icon: "arrow.uturn.backward", color: .gray) {
                    engine.undoLastPoint()
                }
                ScoreActionButton(title: "Rotate", icon: "arrow.clockwise", color: .cyan) {
                    engine.advanceRotation(for: engine.isServing)
                }
            }

            // Quick serve side toggle
            HStack {
                Button { engine.isServing = "home" } label: {
                    HStack { Image(systemName: "hand.raised.fill"); Text("Home Serve") }
                        .font(.caption2).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(engine.isServing == "home" ? Color.pink.opacity(0.4) : Color.black.opacity(0.4))
                        .cornerRadius(8)
                }
                Button { engine.isServing = "away" } label: {
                    HStack { Image(systemName: "hand.raised.fill"); Text("Away Serve") }
                        .font(.caption2).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(engine.isServing == "away" ? Color.blue.opacity(0.4) : Color.black.opacity(0.4))
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Court View Panel
    private var courtViewPanel: some View {
        VStack(spacing: 14) {
            // Court visualization with players
            VStack(spacing: 0) {
                // Away lineup (top half)
                VStack(spacing: 4) {
                    Text("AWAY").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.blue)
                    courtGrid(side: "away")
                }
                .padding(8)
                .background(Color.blue.opacity(0.08))
                .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3)), alignment: .bottom)

                // Net divider
                Rectangle().fill(NeonGlassStyle.neonGradient()).frame(height: 2)

                // Home lineup (bottom half)
                VStack(spacing: 4) {
                    courtGrid(side: "home")
                    Text("\(team.shortName)").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.pink)
                }
                .padding(8)
                .background(Color.pink.opacity(0.08))
            }
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1.5))

            // Rotation control
            HStack(spacing: 20) {
                Button {
                    engine.advanceRotation(for: "away")
                } label: {
                    Label("Rotate Away", systemImage: "arrow.trianglehead.clockwise.rotate.90")
                        .font(.caption2).foregroundColor(.blue).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.5), lineWidth: 1))
                }
                Text("Rotation: \(engine.currentRotation)").font(.system(size: 12, design: .monospaced)).foregroundColor(.white)
                Button {
                    engine.advanceRotation(for: "home")
                } label: {
                    Label("Rotate Home", systemImage: "arrow.trianglehead.clockwise.rotate.90")
                        .font(.caption2).foregroundColor(.pink).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.pink.opacity(0.5), lineWidth: 1))
                }
            }

            // Kill spot heatmap
            VStack(spacing: 8) {
                Text("Kill Spots").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.white)
                killSpotGrid
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 12).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))
        }
    }

    private func courtGrid(side: String) -> some View {
        let positions = side == "home" ? engine.homeCourtPositions : engine.awayCourtPositions
        let order: [[String]] = [
            ["P4", "P3", "P2"],
            ["P5", "P6", "P1"]
        ]
        return VStack(spacing: 6) {
            ForEach(order, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { posID in
                        let player = positions[posID] ?? CourtPlayer(positionID: posID, side: side)
                        Button {
                            assignSide = side
                            assignPosition = posID
                            showPlayerAssignSheet = true
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(player.isEmpty ? .gray.opacity(0.5) : (side == "home" ? .pink : .blue))
                                Text(player.isEmpty ? posID : player.displayName)
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundColor(player.isEmpty ? .gray : .white)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(player.isEmpty ? Color.white.opacity(0.03) : (side == "home" ? Color.pink.opacity(0.2) : Color.blue.opacity(0.2)))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(player.isEmpty ? Color.white.opacity(0.1) : (side == "home" ? Color.pink.opacity(0.4) : Color.blue.opacity(0.4)), lineWidth: 1))
                            .overlay(Group {
                                if engine.servingPlayerID == player.playerID {
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                        .offset(x: 18, y: -20)
                                }
                            })
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var killSpotGrid: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { col in
                        let idx = row * 5 + col + 1
                        let key = "Z\(idx)"
                        let zone = engine.heatmapZones[key]
                        Button {
                            selectedZone = key
                            // Add kill at zone
                            let side = engine.isServing
                            engine.awardPoint(to: side, playerID: engine.servingPlayerID ?? UUID(), eventType: "attack", zoneID: key)
                        } label: {
                            Rectangle()
                                .fill(zoneHitColor(zone))
                                .frame(height: 38)
                                .overlay(
                                    VStack(spacing: 1) {
                                        Text("\(zone?.hitCount ?? 0)")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.white)
                                        Text("\(zone?.killCount ?? 0)K")
                                            .font(.system(size: 7)).foregroundColor(.green.opacity(0.8))
                                    }
                                )
                                .border(Color.white.opacity(0.2), width: 0.5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }

    private func zoneHitColor(_ zone: HeatmapZone?) -> Color {
        guard let zone = zone, zone.hitCount > 0 else { return Color.black.opacity(0.5) }
        if zone.efficiency > 0.35 { return Color.red.opacity(0.6) }
        if zone.hitCount > 3 { return Color.orange.opacity(0.4) }
        return Color.blue.opacity(0.3)
    }

    // MARK: - Stats Panel
    private var statsPanel: some View {
        VStack(spacing: 14) {
            HStack {
                Text("\(team.shortName) Stats").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.pink)
                Spacer()
                Button { statSide = "home"; showPlayerStatPicker = true } label: {
                    Image(systemName: "plus.circle").foregroundColor(.pink)
                }
            }
            if engine.homePlayerStats.isEmpty {
                Text("No home stats yet").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(Array(engine.homePlayerStats.keys), id: \.self) { pid in
                    if let s = engine.homePlayerStats[pid] {
                        let name = engine.playerNames[pid] ?? "Player"
                        StatRow(label: name, kills: s.kills, aces: s.aces, blocks: s.totalBlocks, digs: s.digs)
                    }
                }
            }
            Divider().background(Color.white.opacity(0.2))
            HStack {
                Text("Away Stats").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.blue)
                Spacer()
                Button { statSide = "away"; showPlayerStatPicker = true } label: {
                    Image(systemName: "plus.circle").foregroundColor(.blue)
                }
            }
            if engine.awayPlayerStats.isEmpty {
                Text("No away stats yet").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(Array(engine.awayPlayerStats.keys), id: \.self) { pid in
                    if let s = engine.awayPlayerStats[pid] {
                        let name = engine.playerNames[pid] ?? "Player"
                        StatRow(label: name, kills: s.kills, aces: s.aces, blocks: s.totalBlocks, digs: s.digs)
                    }
                }
            }

            // Team stats summary
            VStack(spacing: 8) {
                Text("Set Summary").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.white)
                HStack {
                    StatCard(title: "Home Kills", value: "\(totalKills(side: "home"))", icon: "flame.fill", color: .pink)
                    StatCard(title: "Away Kills", value: "\(totalKills(side: "away"))", icon: "flame.fill", color: .blue)
                    StatCard(title: "Home Errors", value: "\(totalErrors(side: "home"))", icon: "xmark", color: .red)
                    StatCard(title: "Away Errors", value: "\(totalErrors(side: "away"))", icon: "xmark", color: .red)
                }
            }
        }
    }

    private func totalKills(side: String) -> Int {
        let all = side == "home" ? engine.homePlayerStats : engine.awayPlayerStats
        return all.values.reduce(0) { $0 + $1.kills }
    }
    private func totalErrors(side: String) -> Int {
        let all = side == "home" ? engine.homePlayerStats : engine.awayPlayerStats
        return all.values.reduce(0) { $0 + $1.attackErrors + $1.serveErrors + $1.receptionErrors }
    }

    // MARK: - Play-by-Play Panel
    private var playByPlayPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Play-by-Play").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white)
            if engine.playByPlayLog.isEmpty {
                Text("Match just started...").font(.caption).foregroundColor(.gray).padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(engine.playByPlayLog.reversed().prefix(40)) { entry in
                            HStack(spacing: 6) {
                                Text(entry.formattedTime).font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                                Circle().fill(entry.scoringTeam == "home" ? Color.pink : Color.blue).frame(width: 6, height: 6)
                                Text(entry.description).font(.system(size: 11, design: .rounded)).foregroundColor(.white).lineLimit(2)
                                Spacer()
                                Text("\(entry.homeScoreAfter)-\(entry.awayScoreAfter)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))
    }

    // MARK: - Player Assign Sheet
    private var playerAssignSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                VStack(spacing: 16) {
                    Text("Assign Player to \(assignPosition)")
                        .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                    let t = viewModel.selectedTeam ?? team
                    ForEach(t.players) { player in
                        Button {
                            engine.assignPlayerToPosition(playerID: player.id, playerName: player.fullName, positionID: assignPosition, side: assignSide)
                            showPlayerAssignSheet = false
                        } label: {
                            HStack {
                                Text("#\(player.jerseyNumber)").font(.system(size: 14, design: .monospaced)).foregroundColor(.pink)
                                Text(player.fullName).foregroundColor(.white)
                                Spacer()
                                Text(player.position.rawValue).font(.caption).foregroundColor(.gray)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                        }
                    }
                    Button("Remove from Position") {
                        engine.removePlayerFromPosition(positionID: assignPosition, side: assignSide)
                        showPlayerAssignSheet = false
                    }
                    .font(.caption).foregroundColor(.red).padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Court Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showPlayerAssignSheet = false } } }
        }
    }

    // MARK: - Substitution Sheet
    private var substitutionSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                VStack(spacing: 16) {
                    Text("Substitution - \(subSide.uppercased())").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                    let t = viewModel.selectedTeam ?? team
                    ForEach(t.players) { player in
                        Button {
                            engine.recordSubstitution(team: subSide, playerIn: player.id, playerInName: player.fullName, playerOut: UUID(), playerOutName: "Player Out")
                            showSubSheet = false
                        } label: {
                            HStack {
                                Text("#\(player.jerseyNumber)").foregroundColor(.pink)
                                Text(player.fullName).foregroundColor(.white)
                                Spacer()
                                Text("Sub In").font(.caption).foregroundColor(.green)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showSubSheet = false } } }
        }
    }

    // MARK: - Player Stat Picker Sheet
    private var playerStatSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))
                VStack(spacing: 14) {
                    Text("Record Stat - \(statSide.uppercased())").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                    let t = viewModel.selectedTeam ?? team
                    ForEach(t.players) { player in
                        Menu {
                            Button { recordManualStat(side: statSide, player: player, type: "kill") } label: { Label("Kill", systemImage: "flame") }
                            Button { recordManualStat(side: statSide, player: player, type: "ace") } label: { Label("Ace", systemImage: "bolt") }
                            Button { recordManualStat(side: statSide, player: player, type: "block") } label: { Label("Block", systemImage: "hand.raised") }
                            Button { recordManualStat(side: statSide, player: player, type: "dig") } label: { Label("Dig", systemImage: "arrow.down") }
                            Button { recordManualStat(side: statSide, player: player, type: "assist") } label: { Label("Assist", systemImage: "hand.point.up") }
                            Divider()
                            Button { recordManualStat(side: statSide, player: player, type: "attack_error") } label: { Label("Attack Error", systemImage: "xmark") }
                            Button { recordManualStat(side: statSide, player: player, type: "serve_error") } label: { Label("Serve Error", systemImage: "xmark") }
                        } label: {
                            HStack {
                                Text("#\(player.jerseyNumber)").foregroundColor(.pink)
                                Text(player.fullName).foregroundColor(.white)
                                Spacer()
                                let pid = player.id
                                let ls = (statSide == "home" ? engine.homePlayerStats : engine.awayPlayerStats)[pid]
                                if let ls = ls {
                                    Text("K:\(ls.kills) A:\(ls.aces) B:\(ls.totalBlocks) D:\(ls.digs)")
                                        .font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                                }
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(NeonGlassStyle.glassBackground).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Player Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showPlayerStatPicker = false } } }
        }
    }

    private func recordManualStat(side: String, player: TeamMember, type: String) {
        // check if player ID is not nil
        // guard let pid = player.id else { return } // id is non-optional in TeamMember
        let pid = player.id
        switch type {
        case "kill": engine.awardPoint(to: side, playerID: pid, eventType: "attack")
        case "ace": engine.awardAce(team: side, playerID: pid)
        case "block": engine.awardPoint(to: side, playerID: pid, eventType: "block")
        case "dig": engine.recordPlay(eventType: "dig", description: "\(player.fullName) dig", scoringTeam: side, playerID: pid, playerName: player.fullName)
        case "assist": engine.recordPlay(eventType: "assist", description: "\(player.fullName) assist", scoringTeam: side, playerID: pid, playerName: player.fullName)
        case "attack_error": engine.recordError(team: side, playerID: pid, errorType: "attack_error")
        case "serve_error": engine.recordError(team: side, playerID: pid, errorType: "serve_error")
        default: break
        }
        showPlayerStatPicker = false
    }

    // MARK: - Match Summary
    private var matchSummaryView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: engine.matchWinner == "home" ? "trophy.fill" : "hand.thumbsdown")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .pink.opacity(0.5), radius: 20)

            Text("Match Complete!").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text("\(team.shortName) \(engine.homeSetsWon) - \(engine.awaySetsWon) AWAY")
                .font(.system(size: 22, weight: .bold, design: .monospaced)).foregroundColor(.blue)

            VStack(spacing: 8) {
                ForEach(engine.setHistory) { set in
                    Text("Set \(set.setNumber): \(set.homeScore)-\(set.awayScore)").font(.caption).foregroundColor(.gray)
                }
            }

            Button { dismiss() } label: {
                Text("Done").font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white).padding(.horizontal, 40).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.glassBackground)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 2)))
            }
            Spacer()
        }
    }

    private func timeElapsedString(from start: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(start))
        return String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }
}

// MARK: - Score Action Button
struct ScoreActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
                Text(title).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(pressed ? 0.3 : 0.15))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.4), lineWidth: 1)))
            .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in pressed = true }.onEnded { _ in pressed = false })
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let kills: Int
    let aces: Int
    let blocks: Int
    let digs: Int
    var body: some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 11, design: .rounded)).foregroundColor(.white).frame(width: 55, alignment: .leading).lineLimit(1)
            Spacer()
            StatBadge(label: "K", value: kills, color: .pink)
            StatBadge(label: "A", value: aces, color: .yellow)
            StatBadge(label: "B", value: blocks, color: .purple)
            StatBadge(label: "D", value: digs, color: .green)
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(color)
            Text(label).font(.system(size: 7)).foregroundColor(.gray)
        }.frame(width: 26)
    }
}

// MARK: - Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    LiveScoringView(
        engine: LiveScoringEngine(),
        team: TeamModel(name: "Test Team"),
        viewModel: TeamManagementViewModel()
    )
}