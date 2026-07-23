import SwiftUI
import SwiftData

// MARK: - Live Scoring View

struct LiveScoringView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var engine: LiveScoringEngine
    let team: TeamModel
    @ObservedObject var viewModel: TeamManagementViewModel
    
    @State private var showEndMatchAlert = false
    @State private var showMatchSummary = false
    @State private var showPlayByPlay = false
    @State private var selectedActionTab = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            if engine.isMatchOver && showMatchSummary {
                matchSummaryView
            } else {
                VStack(spacing: 0) {
                    // Top bar
                    topBarView
                    
                    // Scoreboard
                    scoreboardView
                    
                    // Action tabs
                    if !engine.isMatchOver {
                        actionTabs
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                switch selectedActionTab {
                                case 0: scoringActionsView
                                case 1: statActionsView
                                case 2: playByPlayFeedView
                                default: courtVisualizationView
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
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
            Text("Are you sure you want to end the match? Current score: \(engine.homeSetsWon)-\(engine.awaySetsWon)")
        }
    }
    
    // MARK: - Top Bar
    
    private var topBarView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("LIVE SCORING")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    
                    if let start = engine.matchStartTime {
                        Text(timeElapsedString(from: start))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    showEndMatchAlert = true
                }) {
                    Label("End Match", systemImage: "stop.circle")
                }
                Button(action: {
                    engine.undoLastPoint()
                }) {
                    Label("Undo Last Point", systemImage: "arrow.uturn.backward")
                }
                if engine.isOfflineMode {
                    Button(action: { engine.disableOfflineMode() }) {
                        Label("Go Online", systemImage: "wifi")
                    }
                } else {
                    Button(action: { engine.enableOfflineMode() }) {
                        Label("Offline Mode", systemImage: "wifi.slash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Scoreboard
    
    private var scoreboardView: some View {
        VStack(spacing: 8) {
            HStack {
                // Home team
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
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("SERVING")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("Sets: \(engine.homeSetsWon)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                // VS
                VStack(spacing: 6) {
                    Text("VS")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Text("Set \(engine.currentSet)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text("Best of 5")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .frame(width: 60)
                
                // Away team
                VStack(spacing: 4) {
                    Text("AWAY")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("\(engine.awayScore)")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.5), radius: 10)
                    
                    if engine.isServing == "away" {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("SERVING")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("Sets: \(engine.awaySetsWon)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            
            // Set history
            if !engine.setHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(engine.setHistory) { set in
                            HStack(spacing: 4) {
                                Text("S\(set.setNumber)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Text("\(set.homeScore)-\(set.awayScore)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(set.winner == "home" ? .pink : .blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(set.winner == "home" ? Color.pink.opacity(0.5) : Color.blue.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(NeonGlassStyle.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(NeonGlassStyle.neonGradient(), lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Action Tabs
    
    private var actionTabs: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { i in
                Button(action: { withAnimation { selectedActionTab = i } }) {
                    VStack(spacing: 4) {
                        Image(systemName: actionTabIcon(i))
                            .font(.caption)
                        Text(actionTabTitle(i))
                            .font(.system(size: 10, design: .rounded))
                    }
                    .foregroundColor(selectedActionTab == i ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedActionTab == i ? Color.pink.opacity(0.2) : Color.clear
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func actionTabIcon(_ i: Int) -> String {
        ["hand.tap.fill", "chart.bar.fill", "list.bullet.rectangle", "sportscourt.fill"][i]
    }
    
    private func actionTabTitle(_ i: Int) -> String {
        ["Score", "Stats", "Play-by-Play", "Court"][i]
    }
    
    // MARK: - Scoring Actions
    
    private var scoringActionsView: some View {
        VStack(spacing: 16) {
            // Home attack buttons
            VStack(spacing: 10) {
                Text("HOME (\(team.shortName))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.pink)
                
                HStack(spacing: 10) {
                    ScoreActionButton(title: "Kill", icon: "flame.fill", color: .pink) {
                        engine.awardPoint(to: "home", playerID: UUID(), eventType: "attack")
                    }
                    ScoreActionButton(title: "Ace", icon: "bolt.fill", color: .yellow) {
                        engine.awardAce(team: "home", playerID: UUID())
                    }
                    ScoreActionButton(title: "Block", icon: "hand.raised.fill", color: .purple) {
                        engine.awardPoint(to: "home", playerID: UUID(), eventType: "block")
                    }
                    ScoreActionButton(title: "Error", icon: "xmark.circle.fill", color: .red) {
                        engine.recordError(team: "away", playerID: UUID(), errorType: "attack_error")
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NeonGlassStyle.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pink.opacity(0.4), lineWidth: 1)
                    )
            )
            
            // Away attack buttons
            VStack(spacing: 10) {
                Text("AWAY")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
                
                HStack(spacing: 10) {
                    ScoreActionButton(title: "Kill", icon: "flame.fill", color: .blue) {
                        engine.awardPoint(to: "away", playerID: UUID(), eventType: "attack")
                    }
                    ScoreActionButton(title: "Ace", icon: "bolt.fill", color: .yellow) {
                        engine.awardAce(team: "away", playerID: UUID())
                    }
                    ScoreActionButton(title: "Block", icon: "hand.raised.fill", color: .purple) {
                        engine.awardPoint(to: "away", playerID: UUID(), eventType: "block")
                    }
                    ScoreActionButton(title: "Error", icon: "xmark.circle.fill", color: .red) {
                        engine.recordError(team: "home", playerID: UUID(), errorType: "attack_error")
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NeonGlassStyle.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    )
            )
            
            // Game actions
            HStack(spacing: 12) {
                ScoreActionButton(title: "Timeout", icon: "timer", color: .orange) {
                    engine.callTimeout(for: "home")
                }
                ScoreActionButton(title: "Sub", icon: "arrow.triangle.swap", color: .green) {
                    // Open substitution sheet
                }
                ScoreActionButton(title: "Undo", icon: "arrow.uturn.backward", color: .gray) {
                    engine.undoLastPoint()
                }
            }
        }
    }
    
    // MARK: - Stat Actions
    
    private var statActionsView: some View {
        VStack(spacing: 14) {
            // Home stats
            VStack(alignment: .leading, spacing: 8) {
                Text("\(team.shortName) Stats")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.pink)
                
                ForEach(Array(engine.homePlayerStats.keys), id: \.self) { playerID in
                    if let stats = engine.homePlayerStats[playerID] {
                        StatRow(label: "Player", kills: stats.kills, aces: stats.aces,
                                blocks: stats.soloBlocks + stats.blockAssists, digs: stats.digs)
                    }
                }
                if engine.homePlayerStats.isEmpty {
                    Text("No stats recorded yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NeonGlassStyle.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pink.opacity(0.4), lineWidth: 1)
                    )
            )
            
            // Away stats
            VStack(alignment: .leading, spacing: 8) {
                Text("Away Stats")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
                
                ForEach(Array(engine.awayPlayerStats.keys), id: \.self) { playerID in
                    if let stats = engine.awayPlayerStats[playerID] {
                        StatRow(label: "Player", kills: stats.kills, aces: stats.aces,
                                blocks: stats.soloBlocks + stats.blockAssists, digs: stats.digs)
                    }
                }
                if engine.awayPlayerStats.isEmpty {
                    Text("No stats recorded yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(NeonGlassStyle.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Play by Play Feed
    
    private var playByPlayFeedView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Play-by-Play")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            if engine.playByPlayLog.isEmpty {
                Text("Game just started. Events will appear here.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6, pinnedViews: []) {
                            ForEach(engine.playByPlayLog.reversed()) { entry in
                                HStack(spacing: 8) {
                                    Text(entry.formattedTime)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.gray)
                                    
                                    Circle()
                                        .fill(entry.scoringTeam == "home" ? Color.pink : Color.blue)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(entry.description)
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Text("\(entry.homeScoreAfter)-\(entry.awayScoreAfter)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
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
    
    // MARK: - Court Visualization
    
    private var courtVisualizationView: some View {
        VStack(spacing: 12) {
            Text("Court Heatmap")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            // Simplified court grid
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { col in
                            let zoneKey = "Z\(row * 5 + col + 1)"
                            let zone = engine.heatmapZones[zoneKey]
                            Rectangle()
                                .fill(zoneColor(zone))
                                .frame(height: 50)
                                .overlay(
                                    Text(zone?.label ?? "")
                                        .font(.system(size: 7))
                                        .foregroundColor(.white.opacity(0.7))
                                )
                                .border(Color.white.opacity(0.2), width: 0.5)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            
            HStack(spacing: 16) {
                Label("Low", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Label("Medium", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Label("High", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
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
    
    private func zoneColor(_ zone: HeatmapZone?) -> Color {
        guard let zone = zone else { return Color.black.opacity(0.5) }
        if zone.hitCount == 0 { return Color.black.opacity(0.5) }
        if zone.efficiency > 0.3 { return Color.red.opacity(0.7) }
        if zone.hitCount > 2 { return Color.orange.opacity(0.5) }
        return Color.blue.opacity(0.3)
    }
    
    // MARK: - Match Summary View
    
    private var matchSummaryView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: engine.matchWinner == "home" ? "trophy.fill" : "hand.thumbsdown")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .pink.opacity(0.5), radius: 20)
            
            Text("Match Complete!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("\(team.shortName) \(engine.homeSetsWon) - \(engine.awaySetsWon) AWAY")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                ForEach(engine.setHistory) { set in
                    Text("Set \(set.setNumber): \(set.homeScore) - \(set.awayScore)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(NeonGlassStyle.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(NeonGlassStyle.neonGradient(), lineWidth: 2)
                            )
                    )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func timeElapsedString(from start: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
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
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(pressed ? 0.3 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
            )
            .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
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
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)
            
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
            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(width: 28)
    }
}

#Preview {
    LiveScoringView(
        engine: LiveScoringEngine(),
        team: TeamModel(name: "Test Team"),
        viewModel: TeamManagementViewModel()
    )
}