import SwiftUI

struct PlayDesignerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var rotation = 1
    @State private var preServePositions: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var activeServePositions: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var defendLeftPositions: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var defendMiddlePositions: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var defendRightPositions: [CGPoint] = Array(repeating: .zero, count: 6)
    
    @State private var mode: FormationMode = .preServe
    @State private var stepIndex = 0
    
    @State private var playerRoles: [String] = ["OH", "MB", "OPP", "S", "MB", "OH"]
    @State private var playerLabels: [String?] = [nil, nil, nil, nil, nil, nil]
    
    @State private var roleModalVisible = false
    @State private var selectedPlayerIndex: Int?
    @State private var tempLabel = ""
    @State private var tempRole = ""
    
    @State private var showRecordPrompt = false
    @State private var saveModalVisible = false
    @State private var playName = ""
    @State private var validationVisible = false
    @State private var showLibrary = false
    
    @State private var ballPosition: CGPoint = .zero
    @State private var ballVisible = false
    @State private var spin: Angle = .zero
    
    @State private var showInstructions = false
    
    // Play animation state
    @State private var isPlaying = false
    @State private var animationStep = 0
    @State private var playbackPositions: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var savedPlayerPositions: [[CGPoint]] = [] // 5 sets of 6 positions
    @State private var savedRoles: [String] = []
    @State private var savedLabels: [String?] = []
    
    private let width = UIScreen.main.bounds.width
    private let courtHeight: CGFloat = UIScreen.main.bounds.width * 1.1
    private let savedPlaysKey = "SavedVolleyballPlays"
    
    private let roleOptions = ["OH", "MB", "OPP", "S", "L"]
    private let serverIndex = 5
    
    enum FormationMode: String, CaseIterable {
        case preServe = "preServe"
        case activeServe = "activeServe"
        case defendLeft = "defendLeft"
        case defendMiddle = "defendMiddle"
        case defendRight = "defendRight"
    }
    
    let stepLabels = [
        "Step 1/5 — Pre-Serve",
        "Step 2/5 — Active Serve",
        "Step 3/5 — Left Return",
        "Step 4/5 — Middle Return",
        "Step 5/5 — Right Return",
    ]
    
    let playStepLabels = [
        "Pre-Serve Formation",
        "Active Serve",
        "Left Return Defense",
        "Middle Return Defense",
        "Right Return Defense"
    ]
    
    // Base positions as fractional values (0-1) relative to court area
    let sixTwoBase: [Int: [CGPoint]] = [
        1: [
            CGPoint(x: 0.25, y: 0.45), CGPoint(x: 0.50, y: 0.45), CGPoint(x: 0.72, y: 0.45),
            CGPoint(x: 0.25, y: 0.65), CGPoint(x: 0.50, y: 0.65), CGPoint(x: 0.72, y: 0.65)
        ],
        2: [
            CGPoint(x: 0.25, y: 0.45), CGPoint(x: 0.50, y: 0.45), CGPoint(x: 0.72, y: 0.45),
            CGPoint(x: 0.25, y: 0.65), CGPoint(x: 0.50, y: 0.65), CGPoint(x: 0.72, y: 0.65)
        ],
        3: [
            CGPoint(x: 0.25, y: 0.45), CGPoint(x: 0.50, y: 0.45), CGPoint(x: 0.72, y: 0.45),
            CGPoint(x: 0.25, y: 0.65), CGPoint(x: 0.50, y: 0.65), CGPoint(x: 0.72, y: 0.65)
        ],
        4: [
            CGPoint(x: 0.25, y: 0.45), CGPoint(x: 0.50, y: 0.45), CGPoint(x: 0.72, y: 0.45),
            CGPoint(x: 0.25, y: 0.65), CGPoint(x: 0.50, y: 0.65), CGPoint(x: 0.72, y: 0.65)
        ],
        5: [
            CGPoint(x: 0.25, y: 0.45), CGPoint(x: 0.50, y: 0.45), CGPoint(x: 0.72, y: 0.45),
            CGPoint(x: 0.25, y: 0.65), CGPoint(x: 0.50, y: 0.65), CGPoint(x: 0.72, y: 0.65)
        ],
        6: [
            CGPoint(x: 0.25, y: 0.45), CGPoint(x: 0.50, y: 0.45), CGPoint(x: 0.72, y: 0.45),
            CGPoint(x: 0.25, y: 0.65), CGPoint(x: 0.50, y: 0.65), CGPoint(x: 0.72, y: 0.65)
        ]
    ]
    
    // Convert fractional positions to actual CGPoints within the given court frame
    private func convertToScreen(_ fracPos: CGPoint, in courtSize: CGSize) -> CGPoint {
        CGPoint(
            x: fracPos.x * courtSize.width,
            y: fracPos.y * courtSize.height
        )
    }
    
    // Convert screen coordinates to fractional positions
    private func convertToFractional(_ screenPos: CGPoint, in courtSize: CGSize) -> CGPoint {
        CGPoint(
            x: max(0, min(1, screenPos.x / max(1, courtSize.width))),
            y: max(0, min(1, screenPos.y / max(1, courtSize.height)))
        )
    }
    
    var currentPositions: [CGPoint] {
        switch mode {
        case .preServe: return preServePositions
        case .activeServe: return activeServePositions
        case .defendLeft: return defendLeftPositions
        case .defendMiddle: return defendMiddlePositions
        case .defendRight: return defendRightPositions
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                
                Image("court")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height * 0.85)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
                
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back button + instructions toggle
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.pink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.pink.opacity(0.6), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                        
                        if showInstructions {
                            Button("Hide") {
                                showInstructions = false
                            }
                            .foregroundColor(Color(hex: "#888"))
                            .font(.system(size: 13, weight: .semibold))
                        } else {
                            Button(action: { showInstructions = true }) {
                                Text("📘 Instructions")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "#2b6cb0"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#f4f6f8").opacity(0.95))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    
                    if showInstructions {
                        instructionsView
                            .padding(.horizontal, 12)
                            .padding(.top, 2)
                    }
                    
                    // Step label
                    Text(isPlaying ? playStepLabels[animationStep] : stepLabels[stepIndex])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3)
                        .padding(.top, 2)
                    
                    // Go to next step button (hidden during playback)
                    if !isPlaying {
                        Button(action: goToNextStep) {
                            Text(stepIndex < 4 ? "Next Step →" : "Save Play")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: geo.size.width * 0.5)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    } else {
                        Button(action: stopPlay) {
                            Text("Stop Playback")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: geo.size.width * 0.5)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                    
                    // Player area fills remaining space
                    GeometryReader { courtGeo in
                        let courtSize = courtGeo.size
                        ZStack {
                            // Players
                            ForEach(Array(0..<6), id: \.self) { i in
                                let positions: [CGPoint] = isPlaying ? playbackPositions : currentPositions
                                let fracPos = positions.indices.contains(i) ? positions[i] : .zero
                                let screenPos = convertToScreen(fracPos, in: courtSize)
                                let role = isPlaying ? savedRoles[i] : playerRoles[i]
                                let label = isPlaying ? savedLabels[i] : playerLabels[i]
                                let isLibero = role == "L"
                                
                                PlayDesignerPlayerView(
                                    position: screenPos,
                                    role: role,
                                    label: label,
                                    isLibero: isLibero,
                                    isServer: i == 5,
                                    onEdit: {
                                        if !isPlaying {
                                            selectedPlayerIndex = i
                                            tempLabel = label ?? ""
                                            tempRole = role
                                            roleModalVisible = true
                                        }
                                    }
                                )
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            guard !isPlaying else { return }
                                            let newFrac = convertToFractional(value.location, in: courtSize)
                                            updatePosition(at: i, to: newFrac)
                                        }
                                )
                            }
                            
                            // Return ball indicators
                            Circle()
                                .fill(Color(hex: "#ff69b4").opacity(mode == .defendLeft ? 1 : 0.3))
                                .frame(width: 32, height: 32)
                                .shadow(color: Color(hex: "#ff69b4"), radius: mode == .defendLeft ? 6 : 0)
                                .position(x: courtSize.width * 0.2, y: courtSize.height * 0.10)
                            
                            Circle()
                                .fill(Color(hex: "#ff69b4").opacity(mode == .defendMiddle ? 1 : 0.3))
                                .frame(width: 32, height: 32)
                                .shadow(color: Color(hex: "#ff69b4"), radius: mode == .defendMiddle ? 6 : 0)
                                .position(x: courtSize.width * 0.5, y: courtSize.height * 0.10)
                            
                            Circle()
                                .fill(Color(hex: "#ff69b4").opacity(mode == .defendRight ? 1 : 0.3))
                                .frame(width: 32, height: 32)
                                .shadow(color: Color(hex: "#ff69b4"), radius: mode == .defendRight ? 6 : 0)
                                .position(x: courtSize.width * 0.8, y: courtSize.height * 0.10)
                            
                            // Animated ball
                            if ballVisible {
                                Image("volleyball")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .position(x: ballPosition.x, y: ballPosition.y)
                                    .shadow(radius: 3)
                            }
                            
                            if !savedPlayerPositions.isEmpty && !isPlaying {
                                Text("Play saved! Tap Run to view animation.")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                                    .shadow(color: .black, radius: 2)
                                    .position(x: courtSize.width / 2, y: courtSize.height * 0.95)
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Button(action: runSavedPlay) {
                            Text("Run")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(savedPlayerPositions.isEmpty ? Color.gray : Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        .disabled(savedPlayerPositions.isEmpty)
                        
                        Button(action: goToLibrary) {
                            Text("Load")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        
                        Button(action: resetPlay) {
                            Text("Reset")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        
                        Button(action: handleRotate) {
                            Text("Rot\(rotation)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                    }
                    .frame(width: geo.size.width - 24)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, max(2, geo.safeAreaInsets.bottom - 8))
                    .background(Color.black.opacity(0.8))
                    .offset(y: -10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(30)
            }
            .navigationBarHidden(true)
            .onAppear {
                initializePositions()
            }
            .onChange(of: rotation) { _, _ in
                initializePositions()
            }
            .alert("Edit Player", isPresented: $roleModalVisible) {
                VStack {
                    TextField("Name/Number", text: $tempLabel)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Picker("Role", selection: $tempRole) {
                        ForEach(roleOptions, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                }
                Button("Save") {
                    if let index = selectedPlayerIndex {
                        playerLabels[index] = tempLabel.isEmpty ? nil : tempLabel
                        playerRoles[index] = tempRole
                    }
                    tempLabel = ""
                    tempRole = ""
                    selectedPlayerIndex = nil
                    roleModalVisible = false
                }
                Button("Cancel") {
                    tempLabel = ""
                    tempRole = ""
                    selectedPlayerIndex = nil
                    roleModalVisible = false
                }
            }
            .sheet(isPresented: $saveModalVisible) {
                saveModalView
            }
            .sheet(isPresented: $showLibrary) {
                PlayLibraryView { play in
                    loadPlayData(play)
                }
            }
            .alert("Incomplete Play", isPresented: $validationVisible) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please complete all 5 formation steps before saving.")
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("📘 Instructions")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#2b6cb0"))
            
            Text("Drag and drop players to desired positions for each step.")
            Text("Step 1: Set Pre‑Serve Formation.")
            Text("Step 2: Set Active Serve Formation.")
            Text("Steps 3–5: Set Left, Middle, Right Return formations.")
            Text("Tap gear icon to edit name/number and role (OH, MB, OPP, S, L).")
            Text("Libero (L) wears gold, restricted to back row only.")
            Text("Save stores the full play (all 5 formations).")
            Text("Tap Run to animate through the saved play.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#333"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(hex: "#f4f6f8"))
        .cornerRadius(8)
    }
    
    private var saveModalView: some View {
        VStack(spacing: 20) {
            Text("Save Full Play")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#2b6cb0"))
            
            TextField("Play name", text: $playName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(Color(hex: "#333"))
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    saveModalVisible = false
                }
                .foregroundColor(Color(hex: "#888"))
                .font(.system(size: 16, weight: .semibold))
                
                Button("Save") {
                    savePlay()
                }
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#2b6cb0"))
                .cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: 300)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#2b6cb0"), lineWidth: 2)
        )
    }
    
    private func initializePositions() {
        let base = sixTwoBase[rotation]!
        preServePositions = base
        activeServePositions = base
        defendLeftPositions = base
        defendMiddlePositions = base
        defendRightPositions = base
        stepIndex = 0
        mode = .preServe
        isPlaying = false
        animationStep = 0
        ballVisible = false
    }
    
    private func updatePosition(at index: Int, to point: CGPoint) {
        switch mode {
        case .preServe:
            preServePositions[index] = point
        case .activeServe:
            activeServePositions[index] = point
        case .defendLeft:
            defendLeftPositions[index] = point
        case .defendMiddle:
            defendMiddlePositions[index] = point
        case .defendRight:
            defendRightPositions[index] = point
        }
    }
    
    private func handleRotate() {
        guard rotation < 6 else {
            rotation = 1
            return
        }
        rotation += 1
        
        let liberoIndex = playerRoles.firstIndex(of: "L")
        var liberoLabel: String? = nil
        if let idx = liberoIndex {
            liberoLabel = playerLabels[idx]
        }
        
        var roles = playerRoles
        var labels = playerLabels
        
        if let idx = liberoIndex {
            roles.remove(at: idx)
            labels.remove(at: idx)
        }
        
        let clockwiseOrder = [5, 4, 3, 0, 1, 2]
        var orderedRoles = clockwiseOrder.map { roles[$0] }
        var orderedLabels = clockwiseOrder.map { labels[$0] }
        
        let lastRole = orderedRoles.removeLast()
        let lastLabel = orderedLabels.removeLast()
        orderedRoles.insert(lastRole, at: 0)
        orderedLabels.insert(lastLabel, at: 0)
        
        clockwiseOrder.forEach { pos in
            let idx = clockwiseOrder.firstIndex(of: pos) ?? 0
            roles[pos] = orderedRoles[idx]
            labels[pos] = orderedLabels[idx]
        }
        
        if let libIdx = liberoIndex {
            let safeIdx = max(3, min(5, libIdx))
            roles[safeIdx] = "L"
            labels[safeIdx] = liberoLabel
        }
        
        playerRoles = roles
        playerLabels = labels
    }
    
    private func goToNextStep() {
        if stepIndex < 4 {
            stepIndex += 1
            let allModes = FormationMode.allCases
            mode = allModes[stepIndex]
        } else {
            openSaveModal()
        }
    }
    
    private func openSaveModal() {
        let defaultName = "Rotation \(rotation) – Custom Play"
        playName = defaultName
        saveModalVisible = true
    }
    
    private func validateFormations() -> Bool {
        let formations = [
            preServePositions,
            activeServePositions,
            defendLeftPositions,
            defendMiddlePositions,
            defendRightPositions
        ]
        
        let allValid = formations.allSatisfy { $0.count == 6 }
        if !allValid {
            validationVisible = true
            return false
        }
        return true
    }
    
    private func savePlay() {
        let rawName = playName.trimmingCharacters(in: .whitespaces)
        guard !rawName.isEmpty else { return }
        guard validateFormations() else { return }
        
        // Save all 5 formation position sets and current roles/labels
        savedPlayerPositions = [
            preServePositions,
            activeServePositions,
            defendLeftPositions,
            defendMiddlePositions,
            defendRightPositions
        ]
        savedRoles = playerRoles
        savedLabels = playerLabels
        
        // Create SavedPlay and persist to UserDefaults
        let newPlay = SavedPlay(
            name: rawName,
            positions: savedPlayerPositions,
            roles: savedRoles,
            labels: savedLabels
        )
        
        persistSavedPlay(newPlay)
        
        saveModalVisible = false
        playName = ""
    }
    
    private func runSavedPlay() {
        guard !savedPlayerPositions.isEmpty else { return }
        guard !isPlaying else { return }
        
        isPlaying = true
        animationStep = 0
        playbackPositions = currentPositions
        ballVisible = false
        
        let base = sixTwoBase[rotation]!
        withAnimation(.easeInOut(duration: 0.3)) {
            for i in 0..<6 {
                playbackPositions[i] = base[i]
            }
        }
        
        animatePlayStep()
    }
    
    private func animatePlayStep() {
        guard animationStep < savedPlayerPositions.count else {
            isPlaying = false
            animationStep = 0
            ballVisible = false
            return
        }

        let targetPositions = savedPlayerPositions[animationStep]
        withAnimation(.easeInOut(duration: 0.85)) {
            for i in 0..<min(6, targetPositions.count) {
                playbackPositions[i] = targetPositions[i]
            }
        }

        let serverPos = savedPlayerPositions[0][serverIndex]
        let middleReturn = CGPoint(x: 0.5, y: 50 / courtHeight)
        let leftNet = CGPoint(x: 0.2, y: courtHeight * 0.48 / courtHeight)
        let middleNet = CGPoint(x: 0.5, y: courtHeight * 0.48 / courtHeight)
        let rightNet = CGPoint(x: 0.8, y: courtHeight * 0.48 / courtHeight)

        var ballStart: CGPoint
        var ballEnd: CGPoint
        var duration: Double
        var nextDelay: Double
        var showEndMessage = false

        switch animationStep {
        case 0:
            ballStart = serverPos
            ballEnd = middleReturn
            duration = 1.1
            nextDelay = 1.5
        case 1:
            ballStart = middleReturn
            ballEnd = leftNet
            duration = 1.0
            nextDelay = 1.3
        case 2:
            ballStart = leftNet
            ballEnd = middleReturn
            duration = 0.9
            nextDelay = 1.2
        case 3:
            ballStart = middleReturn
            ballEnd = middleNet
            duration = 0.9
            nextDelay = 1.2
        case 4:
            ballStart = middleNet
            ballEnd = middleReturn
            duration = 0.9
            nextDelay = 1.2
        default:
            ballStart = middleReturn
            ballEnd = rightNet
            duration = 1.1
            nextDelay = 1.4
            showEndMessage = true
        }

        ballVisible = true
        ballPosition = CGPoint(x: ballStart.x * width, y: ballStart.y * courtHeight)
        withAnimation(.easeInOut(duration: duration)) {
            ballPosition = CGPoint(x: ballEnd.x * width, y: ballEnd.y * courtHeight)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) { [self] in
            withAnimation {
                ballVisible = false
            }
            animationStep += 1
            if animationStep < savedPlayerPositions.count {
                animatePlayStep()
            } else {
                isPlaying = false
                animationStep = 0
            }
        }
    }
    
    private func stopPlay() {
        isPlaying = false
        animationStep = 0
        ballVisible = false
        let base = sixTwoBase[rotation]!
        withAnimation(.easeInOut(duration: 0.4)) {
            for i in 0..<6 {
                preServePositions[i] = savedPlayerPositions.indices.contains(0) ? savedPlayerPositions[0][i] : base[i]
                activeServePositions[i] = savedPlayerPositions.indices.contains(1) ? savedPlayerPositions[1][i] : base[i]
                defendLeftPositions[i] = savedPlayerPositions.indices.contains(2) ? savedPlayerPositions[2][i] : base[i]
                defendMiddlePositions[i] = savedPlayerPositions.indices.contains(3) ? savedPlayerPositions[3][i] : base[i]
                defendRightPositions[i] = savedPlayerPositions.indices.contains(4) ? savedPlayerPositions[4][i] : base[i]
                playbackPositions[i] = savedPlayerPositions.indices.contains(0) ? savedPlayerPositions[0][i] : base[i]
            }
        }
    }
    
    private func goToLibrary() {
        showLibrary = true
    }
    
    private func resetPlay() {
        initializePositions()
        playerRoles = ["OH", "MB", "OPP", "S", "MB", "OH"]
        playerLabels = [nil, nil, nil, nil, nil, nil]
        savedPlayerPositions = []
        savedRoles = []
        savedLabels = []
        isPlaying = false
        animationStep = 0
        ballVisible = false
    }
}

struct PlayDesignerPlayerView: View {
    let position: CGPoint
    let role: String
    let label: String?
    let isLibero: Bool
    let isServer: Bool
    let onEdit: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isLibero ? Color(hex: "#FFD700") : Color(hex: "#2b6cb0"))
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 1) {
                Text(role)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                if let label = label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(4)
                }
            }
            
            if isServer {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color(hex: "#ff69b4"))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("S")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.trailing, -4)
                    .padding(.bottom, -4)
                }
            }
            
            // Gear icon - lower left
            VStack {
                Spacer()
                HStack {
                    Button(action: onEdit) {
                        Text("⚙️")
                            .font(.system(size: 14))
                    }
                    .padding(.leading, -4)
                    .padding(.bottom, -4)
                    Spacer()
                }
            }
            .frame(width: 40, height: 40)
        }
        .frame(width: 40, height: 40)
        .position(x: position.x, y: position.y)
    }
}

// MARK: - Play Persistence
extension PlayDesignerView {
    private func persistSavedPlay(_ play: SavedPlay) {
        var savedPlays = loadAllSavedPlays()
        savedPlays.append(play)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(savedPlays) {
            UserDefaults.standard.set(data, forKey: savedPlaysKey)
        }
    }
    
    private func loadAllSavedPlays() -> [SavedPlay] {
        guard let data = UserDefaults.standard.data(forKey: savedPlaysKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let plays = try? decoder.decode([SavedPlay].self, from: data) {
            return plays
        } else {
            return []
        }
    }
    
    private func loadPlayData(_ play: SavedPlay) {
        guard play.positions.count >= 5 else { return }
        
        preServePositions = play.positions[0]
        activeServePositions = play.positions[1]
        defendLeftPositions = play.positions[2]
        defendMiddlePositions = play.positions[3]
        defendRightPositions = play.positions[4]
        
        playerRoles = play.roles
        playerLabels = play.labels
        
        savedPlayerPositions = play.positions
        savedRoles = play.roles
        savedLabels = play.labels
    }
}

#Preview {
    PlayDesignerView()
}