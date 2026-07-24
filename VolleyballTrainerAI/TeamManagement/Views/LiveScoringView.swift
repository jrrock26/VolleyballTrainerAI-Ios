import SwiftUI
import SwiftData

// MARK: - Live Scoring View (GameChanger-Style Court)

struct LiveScoringView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
    @State private var showLineupSetup = true
    @State private var showLiveFeedPreview = false
    @State private var liveFeedURL: String = ""
    @State private var showShareSheet = false
    @State private var selectedCourtPlayer: CourtPlayer? = nil
    @State private var showQuickStatMenu = false
    @State private var quickStatSide: String = "home"
    @State private var pendingZoneTap: String? = nil
    @State private var lastSelectedPlayer: CourtPlayer? = nil
    @State private var lastSelectedSide: String = "home"
    @State private var showZonePickerForPlayer = false

    enum LiveTab: String, CaseIterable {
        case court = "Court"
        case score = "Score"
        case stats = "Stats"
        case playbyplay = "Plays"
        var icon: String {
            switch self {
            case .court: return "sportscourt.fill"
            case .score: return "hand.tap.fill"
            case .stats: return "chart.bar.fill"
            case .playbyplay: return "list.bullet.rectangle"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if engine.isMatchOver && showMatchSummary {
                matchSummaryView
            } else if showLineupSetup {
                lineupSetupView
            } else {
                VStack(spacing: 0) {
                    topBarView
                    scoreboardCompactView

                    if !engine.isMatchOver {
                        tabBarCompact
                        ScrollView {
                            VStack(spacing: 12) {
                                switch LiveTab.allCases[safe: selectedTab] ?? .court {
                                case .court: courtMainView
                                case .score: quickScoringPanel
                                case .stats: statsPanel
                                case .playbyplay: playByPlayPanel
                                }
                            }
                            .padding(.horizontal, 10)
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
        .sheet(isPresented: $showQuickStatMenu) {
            quickStatMenuSheet
        }
        .sheet(isPresented: $showLiveFeedPreview) {
            liveFeedPreviewSheet
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
            HStack(spacing: 8) {
                Button {
                    showLiveFeedPreview = true
                } label: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(6)
                        .background(Circle().fill(Color.green.opacity(0.2)))
                }
                Menu {
                    Button { showEndMatchAlert = true } label: {
                        Label("End Match", systemImage: "stop.circle")
                    }
                    Button { engine.undoLastPoint() } label: {
                        Label("Undo Point", systemImage: "arrow.uturn.backward")
                    }
                    Button { showLineupSetup = true } label: {
                        Label("Edit Lineup", systemImage: "person.3")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill").font(.title3).foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal).padding(.top, 12).padding(.bottom, 6)
        .background(Color.black.opacity(0.85))
    }

    // MARK: - Compact Scoreboard
    private var scoreboardCompactView: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text(engine.homeSetsWon > 0 ? "W\(engine.homeSetsWon)" : "")
                    .font(.caption2).foregroundColor(.pink)
                Text(team.shortName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.pink)
                Text("\(engine.homeScore)")
                    .font(.system(size: 38, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .pink.opacity(0.5), radius: 6)
                if engine.isServing == "home" {
                    Text("SERVING").font(.system(size: 8, weight: .bold)).foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text("Set \(engine.currentSet)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.white)
                Text("VS")
                    .font(.system(size: 11, design: .rounded)).foregroundColor(.gray)
                if engine.isTimeoutActive {
                    Text("TIMEOUT")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.orange)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.3)))
                }
            }
            .frame(width: 60)

            VStack(spacing: 2) {
                Text(engine.awaySetsWon > 0 ? "W\(engine.awaySetsWon)" : "")
                    .font(.caption2).foregroundColor(.blue)
                Text("AWAY")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Text("\(engine.awayScore)")
                    .font(.system(size: 38, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .blue.opacity(0.5), radius: 6)
                if engine.isServing == "away" {
                    Text("SERVING").font(.system(size: 8, weight: .bold)).foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8).padding(.horizontal)
        .background(Color.black.opacity(0.55).overlay(
            Rectangle().fill(NeonGlassStyle.neonGradient()).frame(height: 1.5), alignment: .bottom
        ))
    }

    // MARK: - Tab Bar Compact
    private var tabBarCompact: some View {
        HStack(spacing: 0) {
            ForEach(LiveTab.allCases.indices, id: \.self) { i in
                Button {
                    withAnimation { selectedTab = i }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: LiveTab.allCases[i].icon).font(.caption2)
                        Text(LiveTab.allCases[i].rawValue).font(.system(size: 10, design: .rounded))
                    }
                    .foregroundColor(selectedTab == i ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == i ? Color.pink.opacity(0.3) : Color.clear)
                    .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
    }

    // MARK: - Main Court View
    private var courtMainView: some View {
        VStack(spacing: 10) {
            // Full volleyball court with players
            volleyballCourtView

            // Quick action row below court
            HStack(spacing: 8) {
                CourtActionButton(title: "Sub", icon: "arrow.triangle.swap", color: .green) {
                    subSide = engine.isServing; showSubSheet = true
                }
                CourtActionButton(title: "Timeout", icon: "timer", color: .orange) {
                    engine.callTimeout(for: engine.isServing)
                }
                CourtActionButton(title: "Rotate", icon: "arrow.clockwise", color: .cyan) {
                    engine.advanceRotation(for: "home")
                }
                CourtActionButton(title: "Undo", icon: "arrow.uturn.backward", color: .gray) {
                    engine.undoLastPoint()
                }
                CourtActionButton(title: "Serve", icon: "hand.raised.fill", color: engine.isServing == "home" ? .pink : .blue) {
                    engine.switchSides()
                }
            }
        }
    }

    // MARK: - Volleyball Court
    private var volleyballCourtView: some View {
        VStack(spacing: 0) {
            // Away side (top)
            VStack(spacing: 0) {
                Text("AWAY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
                courtPlayerGrid(side: "away", isFlipped: true)
            }
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.12), Color.blue.opacity(0.04)],
                               startPoint: .bottom, endPoint: .top)
            )

            // Net
            ZStack {
                Rectangle().fill(Color.white.opacity(0.4)).frame(height: 2)
                HStack {
                    ForEach(0..<12, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 3, height: 12)
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3))

            // Home side (bottom)
            VStack(spacing: 0) {
                courtPlayerGrid(side: "home", isFlipped: false)
                Text(team.shortName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.pink)
                    .padding(.vertical, 4)
            }
            .background(
                LinearGradient(colors: [Color.pink.opacity(0.04), Color.pink.opacity(0.12)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1.5))
        .overlay(
            // Court boundary lines
            courtBoundaryLines
        )
    }

    private var courtBoundaryLines: some View {
        GeometryReader { geo in
            ZStack {
                // Attack line top
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: geo.size.width * 0.85, height: 1)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.29)

                // Attack line bottom
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: geo.size.width * 0.85, height: 1)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.71)

                // Center vertical line
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: geo.size.height * 0.35)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
            }
        }
    }

    // MARK: - Court Player Grid
    private func courtPlayerGrid(side: String, isFlipped: Bool) -> some View {
        let positions = side == "home" ? engine.homeCourtPositions : engine.awayCourtPositions
        let frontRow: [String] = isFlipped ? ["P2", "P3", "P4"] : ["P4", "P3", "P2"]
        let backRow: [String] = isFlipped ? ["P1", "P6", "P5"] : ["P5", "P6", "P1"]
        let rows = isFlipped ? [frontRow, backRow] : [backRow, frontRow]

        return VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { posID in
                        let player = positions[posID] ?? CourtPlayer(positionID: posID, side: side)
                        courtPlayerCell(player: player, posID: posID, side: side)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Court Player Cell
    private func courtPlayerCell(player: CourtPlayer, posID: String, side: String) -> some View {
        let sideColor = side == "home" ? Color.pink : Color.blue
        let isServing = engine.servingPlayerID == player.playerID && engine.isServing == side

        return Button {
            if player.isEmpty {
                assignSide = side
                assignPosition = posID
                showPlayerAssignSheet = true
            } else {
                lastSelectedPlayer = player
                lastSelectedSide = side
                showQuickStatMenu = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(player.isEmpty ? Color.white.opacity(0.04) : sideColor.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isServing ? Color.green : (player.isEmpty ? Color.white.opacity(0.1) : sideColor.opacity(0.35)), lineWidth: isServing ? 2 : 1)
                    )

                VStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .fill(player.isEmpty ? Color.clear : sideColor.opacity(0.25))
                            .frame(width: 32, height: 32)
                        if player.isEmpty {
                            Image(systemName: "person.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.4))
                            Text(posID)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.5))
                                .offset(y: 18)
                        } else {
                            Text(player.displayName.prefix(2).uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }

                    if !player.isEmpty {
                        Text(player.displayName)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let pid = player.playerID, let stats = (side == "home" ? engine.homePlayerStats : engine.awayPlayerStats)[pid] {
                            Text("K:\(stats.kills) B:\(stats.totalBlocks)")
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 4)

                // Serving indicator
                if isServing {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .offset(x: -22, y: -28)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Stat Menu Sheet
    private var quickStatMenuSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().overlay(Color.black.opacity(0.7))

                VStack(spacing: 20) {
                    if let player = lastSelectedPlayer {
                        // Player info header
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill((lastSelectedSide == "home" ? Color.pink : Color.blue).opacity(0.3))
                                    .frame(width: 60, height: 60)
                                Text(player.displayName.prefix(2).uppercased())
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Text(player.displayName)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            if let pid = player.playerID, let stats = (lastSelectedSide == "home" ? engine.homePlayerStats : engine.awayPlayerStats)[pid] {
                                Text("K:\(stats.kills) A:\(stats.aces) B:\(stats.totalBlocks) D:\(stats.digs)")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            Text("\(lastSelectedSide.uppercased()) TEAM")
                                .font(.caption).foregroundColor(lastSelectedSide == "home" ? .pink : .blue)
                        }

                        // Zone selection grid (where on court the point was scored)
                        VStack(spacing: 8) {
                            Text("Select Zone on Court")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            zoneSelectionGrid
                        }

                        Divider().background(Color.white.opacity(0.2))

                        // Stat buttons
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            QuickStatButton(title: "Kill", icon: "flame.fill", color: .orange) {
                                recordWithZone(eventType: "attack", player: player)
                            }
                            QuickStatButton(title: "Ace", icon: "bolt.fill", color: .yellow) {
                                recordWithZone(eventType: "ace", player: player)
                            }
                            QuickStatButton(title: "Block", icon: "hand.raised.fill", color: .purple) {
                                recordWithZone(eventType: "block", player: player)
                            }
                            QuickStatButton(title: "Attack Error", icon: "xmark.circle.fill", color: .red) {
                                engine.recordError(team: lastSelectedSide, playerID: player.playerID ?? UUID(),
                                                   playerName: player.displayName, errorType: "attack_error")
                                showQuickStatMenu = false
                            }
                            QuickStatButton(title: "Dig", icon: "arrow.down.to.line", color: .green) {
                                engine.recordPlay(eventType: "dig", description: "\(player.displayName) dig",
                                                  scoringTeam: lastSelectedSide, playerID: player.playerID ?? UUID(), playerName: player.displayName)
                                showQuickStatMenu = false
                            }
                            QuickStatButton(title: "Assist", icon: "hand.point.up.fill", color: .cyan) {
                                engine.recordPlay(eventType: "assist", description: "\(player.displayName) assist",
                                                  scoringTeam: lastSelectedSide, playerID: player.playerID ?? UUID(), playerName: player.displayName)
                                showQuickStatMenu = false
                            }
                        }

                        Button {
                            // Set as server
                            engine.setServer(playerID: player.playerID ?? UUID(), side: lastSelectedSide)
                            showQuickStatMenu = false
                        } label: {
                            Label("Set as Server", systemImage: "hand.raised.fill")
                                .font(.caption).foregroundColor(.green).padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Record Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showQuickStatMenu = false } } }
        }
    }

    // MARK: - Zone Selection Grid
    private var zoneSelectionGrid: some View {
        VStack(spacing: 4) {
            // Front zones (net side) - Zones 1-6 for front row
            HStack(spacing: 4) {
                ForEach(1...6, id: \.self) { i in
                    zoneCell(zoneID: "Z\(i)", label: "Z\(i)", isSelected: selectedZone == "Z\(i)")
                }
            }
            // Back zones - Zones 7-12
            HStack(spacing: 4) {
                ForEach(7...12, id: \.self) { i in
                    zoneCell(zoneID: "Z\(i)", label: "Z\(i)", isSelected: selectedZone == "Z\(i)")
                }
            }
        }
    }

    private func zoneCell(zoneID: String, label: String, isSelected: Bool) -> some View {
        Button {
            withAnimation { selectedZone = isSelected ? nil : zoneID }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.orange.opacity(0.5) : Color.white.opacity(0.08))
                    .frame(height: 36)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? Color.orange : Color.white.opacity(0.2), lineWidth: 1))
                VStack(spacing: 1) {
                    Text(label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? .white : .gray)
                    if let zone = engine.heatmapZones[zoneID] {
                        Text("\(zone.killCount)K")
                            .font(.system(size: 7))
                            .foregroundColor(zone.killCount > 0 ? .green.opacity(0.8) : .gray)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func recordWithZone(eventType: String, player: CourtPlayer) {
        let zone = selectedZone ?? ""
        let pid = player.playerID ?? UUID()
        switch eventType {
        case "attack":
            engine.awardPoint(to: lastSelectedSide, playerID: pid, eventType: "attack", zoneID: zone.isEmpty ? nil : zone, playerName: player.displayName)
        case "ace":
            engine.awardAce(team: lastSelectedSide, playerID: pid, playerName: player.displayName, zoneID: zone.isEmpty ? nil : zone)
        case "block":
            engine.awardPoint(to: lastSelectedSide, playerID: pid, eventType: "block", zoneID: zone.isEmpty ? nil : zone, playerName: player.displayName)
        default:
            engine.recordPlay(eventType: eventType, description: "\(player.displayName) \(eventType)",
                              scoringTeam: lastSelectedSide, playerID: pid, playerName: player.displayName)
        }
        selectedZone = nil
        showQuickStatMenu = false
    }

    // MARK: - Quick Scoring Panel (tab alternative)
    private var quickScoringPanel: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("HOME (\(team.shortName))").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.pink)
                HStack(spacing: 6) {
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

            VStack(spacing: 6) {
                Text("AWAY").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.blue)
                HStack(spacing: 6) {
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

    // MARK: - Stats Panel
    private var statsPanel: some View {
        VStack(spacing: 14) {
            HStack {
                Text("\(team.shortName) Stats").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.pink)
                Spacer()
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
            VStack(spacing: 8) {
                Text("Set Summary").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.white)
                HStack {
                    StatCard(title: "Home Kills", value: "\(totalKills(side: "home"))", icon: "flame.fill", color: .pink)
                    StatCard(title: "Away Kills", value: "\(totalKills(side: "away"))", icon: "flame.fill", color: .blue)
                    StatCard(title: "Home Err", value: "\(totalErrors(side: "home"))", icon: "xmark", color: .red)
                    StatCard(title: "Away Err", value: "\(totalErrors(side: "away"))", icon: "xmark", color: .red)
                }
            }
        }
    }

    private func totalKills(side: String) -> Int {
        (side == "home" ? engine.homePlayerStats : engine.awayPlayerStats).values.reduce(0) { $0 + $1.kills }
    }
    private func totalErrors(side: String) -> Int {
        (side == "home" ? engine.homePlayerStats : engine.awayPlayerStats).values.reduce(0) { $0 + $1.attackErrors + $1.serveErrors + $1.receptionErrors }
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
                                Text("\(entry.homeScoreAfter)-\(entry.awayScoreAfter)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray)
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

    // MARK: - Lineup Setup View
    private var lineupSetupView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SET LINEUP")
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                Spacer()
                Button("Done") {
                    showLineupSetup = false
                }
                .font(.system(size: 14, weight: .semibold)).foregroundColor(.green)
            }
            .padding(.horizontal).padding(.top, 54).padding(.bottom, 12)
            .background(Color.black.opacity(0.9))

            ScrollView {
                VStack(spacing: 20) {
                    // Home lineup
                    VStack(spacing: 8) {
                        Text("\(team.shortName) Lineup").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.pink)
                        lineupGrid(side: "home")
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pink.opacity(0.4), lineWidth: 1)))

                    // Away lineup
                    VStack(spacing: 8) {
                        Text("Away Lineup").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.blue)
                        lineupGrid(side: "away")
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.4), lineWidth: 1)))

                    Button {
                        engine.startMatch()
                        showLineupSetup = false
                    } label: {
                        Text("Start Match").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.neonGradient()))
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func lineupGrid(side: String) -> some View {
        let positions = side == "home" ? engine.homeCourtPositions : engine.awayCourtPositions
        return VStack(spacing: 6) {
            ForEach(["P4", "P3", "P2"], id: \.self) { posID in
                lineupPositionRow(posID: posID, player: positions[posID] ?? CourtPlayer(positionID: posID, side: side), side: side)
            }
            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1).padding(.vertical, 2)
            ForEach(["P5", "P6", "P1"], id: \.self) { posID in
                lineupPositionRow(posID: posID, player: positions[posID] ?? CourtPlayer(positionID: posID, side: side), side: side)
            }
        }
    }

    private func lineupPositionRow(posID: String, player: CourtPlayer, side: String) -> some View {
        let sideColor = side == "home" ? Color.pink : Color.blue
        return Button {
            assignSide = side
            assignPosition = posID
            showPlayerAssignSheet = true
        } label: {
            HStack {
                Text(posID)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(sideColor)
                    .frame(width: 28, alignment: .leading)
                if player.isEmpty {
                    Text("Tap to assign player")
                        .font(.caption).foregroundColor(.gray)
                } else {
                    Text(player.displayName).font(.system(size: 13, design: .rounded)).foregroundColor(.white)
                }
                Spacer()
                Image(systemName: player.isEmpty ? "plus.circle" : "arrow.triangle.swap")
                    .font(.caption).foregroundColor(sideColor)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
        }
        .buttonStyle(.plain)
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

    // MARK: - Live Feed Preview
    private var liveFeedPreviewSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundStyle(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("Live Match Feed")
                        .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)

                    VStack(spacing: 12) {
                        feedInfoRow(title: "Match", value: "\(team.shortName) vs AWAY")
                        feedInfoRow(title: "Score", value: "\(engine.homeSetsWon)-\(engine.awaySetsWon) (Set \(engine.currentSet): \(engine.homeScore)-\(engine.awayScore))")
                        feedInfoRow(title: "Status", value: engine.isMatchOver ? "Final" : "LIVE")
                        feedInfoRow(title: "Feed URL", value: liveFeedURL.isEmpty ? "Generating..." : liveFeedURL)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.55)).overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 1)))

                    VStack(spacing: 12) {
                        Button {
                            generateLiveFeedURL()
                        } label: {
                            Label("Generate Feed Link", systemImage: "link")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.3)))
                        }

                        if !liveFeedURL.isEmpty {
                            Button {
                                UIPasteboard.general.string = liveFeedURL
                            } label: {
                                Label("Copy Link", systemImage: "doc.on.doc")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.5), lineWidth: 1))
                            }

                            Button {
                                let text = generateMatchUpdateText()
                                let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    rootVC.present(av, animated: true)
                                }
                            } label: {
                                Label("Share Update", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.pink.opacity(0.5), lineWidth: 1))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Live Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showLiveFeedPreview = false } } }
        }
    }

    private func feedInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title).font(.caption).foregroundColor(.gray).frame(width: 70, alignment: .leading)
            Text(value).font(.system(size: 13, design: .rounded)).foregroundColor(.white)
            Spacer()
        }
    }

    private func generateLiveFeedURL() {
        let matchID = UUID().uuidString.prefix(8)
        liveFeedURL = "volleytrainer://live/\(matchID)"
    }

    private func generateMatchUpdateText() -> String {
        var text = "🏐 Match Update\n\(team.shortName) vs AWAY\n"
        text += "Score: \(engine.homeSetsWon)-\(engine.awaySetsWon) sets\n"
        text += "Set \(engine.currentSet): \(engine.homeScore)-\(engine.awayScore)\n"
        if let lastPlay = engine.playByPlayLog.last {
            text += "Last: \(lastPlay.description)\n"
        }
        text += "\nPowered by Volleyball Trainer Pro"
        return text
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

            HStack(spacing: 20) {
                Button { dismiss() } label: {
                    Text("Done").font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white).padding(.horizontal, 40).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(NeonGlassStyle.glassBackground)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(NeonGlassStyle.neonGradient(), lineWidth: 2)))
                }
                Button {
                    let text = generateMatchUpdateText()
                    let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(av, animated: true)
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.green)
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.5), lineWidth: 1))
                }
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

// MARK: - Court Action Button
struct CourtActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                Text(title).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Stat Button
struct QuickStatButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
                Text(title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1)))
        }
        .buttonStyle(.plain)
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