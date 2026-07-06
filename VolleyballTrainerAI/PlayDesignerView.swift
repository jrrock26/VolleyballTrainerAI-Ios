import SwiftUI
import Photos

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
    @State private var tempLibero = false
    @State private var previousRoles: [String] = Array(repeating: "", count: 6)
    
    @State private var showRecordPrompt = false
    @State private var saveModalVisible = false
    @State private var playName = ""
    @State private var validationVisible = false
    @State private var showLibrary = false
    
    @State private var ballPosition: CGPoint = .zero
    @State private var ballVisible = false
    @State private var spin: Angle = .zero
    
    @State private var showInstructions = false
    @State private var isRecording = false
    @State private var showRecordAlert = false
    @State private var showSaveRecordingAlert = false
    @State private var courtSize: CGSize = .zero
    @State private var showSaveRecordingPrompt = false
    @State private var recordingSaveError: String?
    
    @StateObject private var screenCapture = ScreenCaptureManager()
    
    @State private var isPlaying = false
    @State private var animationStep = 0
    @State private var playbackPositions: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var savedPlayerPositions: [[CGPoint]] = []
    @State private var savedRoles: [String] = []
    @State private var savedLabels: [String?] = []
    
    private let savedPlaysKey = "SavedVolleyballPlays"
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
    
    private func convertToScreen(_ fracPos: CGPoint, in courtSize: CGSize) -> CGPoint {
        CGPoint(x: fracPos.x * courtSize.width, y: fracPos.y * courtSize.height)
    }
    
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
                Image("background").resizable().scaledToFill().ignoresSafeArea()
                Color.black.opacity(0.35).ignoresSafeArea()
                Image("court").resizable().scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height * 0.85)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
                Color.black.opacity(0.15).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            if isPlaying { stopPlay() }
                            dismiss()
                        }) {
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
                        .disabled(isPlaying)
                        Spacer()
                        
                        if showInstructions {
                            Button("Hide") { showInstructions = false }
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
                    .opacity(isPlaying ? 0 : 1)
                    
                    if showInstructions {
                        instructionsView.padding(.horizontal, 12).padding(.top, 2)
                            .opacity(isPlaying ? 0 : 1)
                    }
                    
                    Text(isPlaying && !playName.isEmpty ? playName : (isPlaying ? "Playing..." : stepLabels[stepIndex]))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3)
                        .padding(.top, 2)
                    
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
                    .opacity(isPlaying ? 0 : 1)
                    .disabled(isPlaying)
                    
                    GeometryReader { courtGeo in
                        let courtSize = courtGeo.size
                        ZStack {
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
                                            tempLibero = role == "L"
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
                            
                            Circle().fill(Color(hex: "#ff69b4").opacity(0))
                                .frame(width: 32, height: 32)
                                .position(x: courtSize.width * 0.2, y: courtSize.height * 0.18)
                            
                            Circle().fill(Color(hex: "#ff69b4").opacity(mode == .defendMiddle ? 1 : 0.3))
                                .frame(width: 32, height: 32)
                                .shadow(color: Color(hex: "#ff69b4"), radius: mode == .defendMiddle ? 6 : 0)
                                .position(x: courtSize.width * 0.5, y: courtSize.height * 0.08)
                            
                            Circle().fill(Color(hex: "#ff69b4").opacity(0))
                                .frame(width: 32, height: 32)
                                .position(x: courtSize.width * 0.8, y: courtSize.height * 0.13)
                            
                            if ballVisible {
                                Image("volleyball").resizable()
                                    .frame(width: 32, height: 32)
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
                        Button(action: { showRecordAlert = true }) {
                            Text("Run").font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(savedPlayerPositions.isEmpty ? Color.gray : Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        .disabled(savedPlayerPositions.isEmpty || isPlaying)
                        
                        Button(action: goToLibrary) {
                            Text("Load").font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        .disabled(isPlaying)
                        
                        Button(action: resetPlay) {
                            Text("Reset").font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        .disabled(isPlaying)
                        
                        Button(action: handleRotate) {
                            Text("Rot\(rotation)").font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        .disabled(isPlaying)
                    }
                    .frame(width: geo.size.width - 24)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, max(2, geo.safeAreaInsets.bottom - 8))
                    .background(Color.black.opacity(0.8))
                    .offset(y: -50)
                    .opacity(isPlaying ? 0 : 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(30)
            }
            .navigationBarHidden(true)
            .onAppear {
                initializePositions()
                setupScreenCaptureCallbacks()
            }
            .onChange(of: rotation) { _, _ in
                if !isPlaying {
                    initializePositions()
                }
            }
            .sheet(isPresented: $roleModalVisible, onDismiss: {
                tempLabel = ""
                tempLibero = false
                selectedPlayerIndex = nil
            }) {
                EditPlayerView(
                    tempLabel: $tempLabel,
                    tempLibero: $tempLibero,
                    onSave: {
                        if let index = selectedPlayerIndex {
                            playerLabels[index] = tempLabel.isEmpty ? nil : tempLabel
                            
                            if tempLibero && !playerRoles.contains("L") {
                                previousRoles[index] = playerRoles[index]
                                if index >= 3 {
                                    playerRoles[index] = "L"
                                }
                            } else if !tempLibero && playerRoles[index] == "L" {
                                playerRoles[index] = previousRoles[index].isEmpty ? "OH" : previousRoles[index]
                                previousRoles[index] = ""
                            }
                        }
                        roleModalVisible = false
                    },
                    onCancel: {
                        roleModalVisible = false
                    }
                )
            }
            .sheet(isPresented: $saveModalVisible) { saveModalView }
            .sheet(isPresented: $showLibrary) {
                PlayLibraryView { play in loadPlayData(play) }
            }
            .alert("Record Play?", isPresented: $showRecordAlert) {
                Button("Yes, Record") { startRecordingAndPlay() }
                Button("No, Just Run") { runSavedPlay() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Do you want to screen record this play?")
            }
            .alert("Incomplete Play", isPresented: $validationVisible) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please complete all 5 formation steps before saving.")
            }
            .alert("Recording Finished", isPresented: $showSaveRecordingPrompt) {
                Button("Save to Camera Roll") { saveRecordingToCameraRoll() }
                Button("Discard", role: .destructive) { screenCapture.cleanupFile() }
                Button("Cancel", role: .cancel) { screenCapture.cleanupFile() }
            } message: {
                Text("The play recording is complete. Would you like to save it to your camera roll?")
            }
            .alert("Recording Error", isPresented: .init(
                get: { recordingSaveError != nil },
                set: { if !$0 { recordingSaveError = nil } }
            )) {
                Button("OK", role: .cancel) { recordingSaveError = nil }
            } message: {
                Text(recordingSaveError ?? "An unknown error occurred.")
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("📘 Instructions").font(.system(size: 13, weight: .bold)).foregroundColor(Color(hex: "#2b6cb0"))
            Text("Drag and drop players to desired positions for each step.")
            Text("Step 1: Set Pre‑Serve Formation.")
            Text("Step 2: Set Active Serve Formation.")
            Text("Steps 3–5: Set Left, Middle, Right Return formations.")
            Text("Tap gear icon to edit name/number and libero.")
            Text("Libero (L) wears gold, back row only.")
            Text("Save stores the full play.")
            Text("Tap Run to animate.")
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
            Text("Save Full Play").font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "#2b6cb0"))
            TextField("Play name", text: $playName).textFieldStyle(RoundedBorderTextFieldStyle())
            HStack(spacing: 20) {
                Button("Cancel") { saveModalVisible = false }.foregroundColor(Color(hex: "#888"))
                Button("Save") {
                    if isPlaying { stopPlay() }
                    savePlay()
                }
                .foregroundColor(.white).font(.system(size: 16, weight: .bold))
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color(hex: "#2b6cb0")).cornerRadius(6)
            }
        }
        .padding().frame(maxWidth: 300).background(Color.white).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#2b6cb0"), lineWidth: 2))
    }
    
    private func setupScreenCaptureCallbacks() {
        screenCapture.onRecordingComplete = { url in
            DispatchQueue.main.async { showSaveRecordingPrompt = true }
        }
        screenCapture.onRecordingError = { errorMessage in
            DispatchQueue.main.async {
                recordingSaveError = errorMessage
                isRecording = false
            }
        }
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
        case .preServe: preServePositions[index] = point
        case .activeServe: activeServePositions[index] = point
        case .defendLeft: defendLeftPositions[index] = point
        case .defendMiddle: defendMiddlePositions[index] = point
        case .defendRight: defendRightPositions[index] = point
        }
    }
    
    private func handleRotate() {
        rotation += 1
        if rotation > 6 {
            rotation = 1
        }
        
        var roles = playerRoles
        var labels = playerLabels
        
        if let liberoIndex = roles.firstIndex(of: "L") {
            // Libero ON: keep libero fixed, rotate only the 5 non-libero positions
            // Position labels stay fixed to their court locations
            var newRoles = roles
            let sourceToDest: [Int: Int] = buildLiberoRotation(liberoIndex: liberoIndex)
            
            for (source, dest) in sourceToDest {
                if !isLibero(at: source, in: roles) {
                    newRoles[dest] = roles[source]
                }
            }
            
            roles = newRoles
        } else {
            // Standard 6-player rotation
            let newRoles = [
                roles[3],
                roles[0],
                roles[1],
                roles[4],
                roles[5],
                roles[2]
            ]
            let newLabels = [
                labels[3],
                labels[0],
                labels[1],
                labels[4],
                labels[5],
                labels[2]
            ]
            
            for i in 0..<6 {
                roles[i] = newRoles[i]
                labels[i] = newLabels[i]
            }
        }
        
        playerRoles = roles
    }
    
    private func buildLiberoRotation(liberoIndex: Int) -> [Int: Int] {
        switch liberoIndex {
        case 3:
            return [0: 1, 1: 2, 2: 5, 5: 4, 4: 0, 3: 3]
        case 4:
            return [0: 1, 1: 2, 2: 5, 5: 3, 3: 0, 4: 4]
        case 5:
            return [0: 1, 1: 2, 2: 4, 3: 0, 4: 3, 5: 5]
        default:
            let nonLib = [0, 1, 2, 3, 4, 5].filter { $0 != liberoIndex }
            var result: [Int: Int] = [:]
            for i in 0..<nonLib.count {
                let source = nonLib[i]
                let dest = nonLib[(i + 1) % nonLib.count]
                result[source] = dest
            }
            result[liberoIndex] = liberoIndex
            return result
        }
    }
    
    private func isLibero(at index: Int, in roles: [String]) -> Bool {
        return roles.indices.contains(index) && roles[index] == "L"
    }
    
    private func goToNextStep() {
        if stepIndex < 4 {
            stepIndex += 1
            mode = FormationMode.allCases[stepIndex]
        } else {
            openSaveModal()
        }
    }
    
    private func openSaveModal() {
        playName = "Rotation \(rotation) – Custom Play"
        saveModalVisible = true
    }
    
    private func validateFormations() -> Bool {
        let formations = [preServePositions, activeServePositions, defendLeftPositions, defendMiddlePositions, defendRightPositions]
        return formations.allSatisfy { $0.count == 6 }
    }
    
    private func savePlay() {
        let rawName = playName.trimmingCharacters(in: .whitespaces)
        guard !rawName.isEmpty else { return }
        guard validateFormations() else { return }
        
        savedPlayerPositions = [preServePositions, activeServePositions, defendLeftPositions, defendMiddlePositions, defendRightPositions]
        savedRoles = playerRoles
        savedLabels = playerLabels
        
        let newPlay = SavedPlay(name: rawName, positions: savedPlayerPositions, roles: savedRoles, labels: savedLabels)
        persistSavedPlay(newPlay)
        saveModalVisible = false
    }
    
    private func runSavedPlay() {
        guard !savedPlayerPositions.isEmpty else { return }
        guard !isPlaying else { return }
        
        isPlaying = true
        animationStep = 0
        playbackPositions = currentPositions
        ballVisible = false
        
        withAnimation(.easeInOut(duration: 1.5)) {
            for i in 0..<6 {
                playbackPositions[i] = savedPlayerPositions[0][i]
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.animatePlayStep()
        }
    }
    
    private func positionOneIndex(in positions: [CGPoint]) -> Int {
        guard positions.count == 6 else { return 5 }

        // Position 1 = back-right player (largest X and largest Y)
        var bestIndex = 0
        var bestScore: CGFloat = -.greatestFiniteMagnitude

        for (index, point) in positions.enumerated() {
            let score = point.x + point.y
            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        return bestIndex
    }
    
    
    private func animatePlayStep(_ courtSize: CGSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.85 * 1.1)) {

        let courtHeight = courtSize.height

        // Fixed serve origin (bottom-right service area)
        // Adjust these two numbers until it lines up perfectly with your court graphic.
        let serveOrigin = CGPoint(x: 0.82, y: 1.5)

        let middleReturnBall = CGPoint(x: 0.5, y: 0.23)
        let leftNet = CGPoint(x: 0.2, y: 0.95)
        let middleNet = CGPoint(x: 0.5, y: 0.95)
        let rightNet = CGPoint(x: 0.8, y: 0.95)

        switch animationStep {
        case 0:
            let targetPositions = savedPlayerPositions[1]

            withAnimation(.easeInOut(duration: 2.0)) {
                for i in 0..<min(6, targetPositions.count) {
                    playbackPositions[i] = targetPositions[i]
                }
            }

            ballVisible = true

            // Always start the serve from the same location.
            ballPosition = CGPoint(
                x: serveOrigin.x * courtSize.width,
                y: serveOrigin.y * courtHeight
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                withAnimation(.easeInOut(duration: 3.0)) {
                    ballPosition = CGPoint(
                        x: middleReturnBall.x * courtSize.width,
                        y: middleReturnBall.y * courtHeight
                    )
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
                withAnimation { ballVisible = false }
                animationStep = 1
                animatePlayStep()
            }

        // ...leave the rest of animatePlayStep() exactly as it is...
            
        case 1:
            let targetPositions = savedPlayerPositions[2]
            withAnimation(.easeInOut(duration: 2.0)) {
                for i in 0..<min(6, targetPositions.count) {
                    playbackPositions[i] = targetPositions[i]
                }
            }
            ballVisible = true
            ballPosition = CGPoint(x: middleReturnBall.x * courtSize.width, y: middleReturnBall.y * courtHeight)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                withAnimation(.easeInOut(duration: 2.5)) {
                    ballPosition = CGPoint(x: leftNet.x * courtSize.width, y: leftNet.y * courtHeight)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                withAnimation(.easeInOut(duration: 2.5)) {
                    ballPosition = CGPoint(x: middleReturnBall.x * courtSize.width, y: middleReturnBall.y * courtHeight)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.8) { [self] in
                withAnimation { ballVisible = false }
                animationStep = 2
                animatePlayStep()
            }
            
        case 2:
            let targetPositions = savedPlayerPositions[3]
            withAnimation(.easeInOut(duration: 2.0)) {
                for i in 0..<min(6, targetPositions.count) {
                    playbackPositions[i] = targetPositions[i]
                }
            }
            ballVisible = true
            ballPosition = CGPoint(x: middleReturnBall.x * courtSize.width, y: middleReturnBall.y * courtHeight)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                withAnimation(.easeInOut(duration: 2.5)) {
                    ballPosition = CGPoint(x: middleNet.x * courtSize.width, y: middleNet.y * courtHeight)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                withAnimation(.easeInOut(duration: 2.5)) {
                    ballPosition = CGPoint(x: middleReturnBall.x * courtSize.width, y: middleReturnBall.y * courtHeight)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.8) { [self] in
                withAnimation { ballVisible = false }
                animationStep = 3
                animatePlayStep()
            }
            
        case 3:
            let targetPositions = savedPlayerPositions[4]
            withAnimation(.easeInOut(duration: 2.0)) {
                for i in 0..<min(6, targetPositions.count) {
                    playbackPositions[i] = targetPositions[i]
                }
            }
            ballVisible = true
            ballPosition = CGPoint(x: middleReturnBall.x * courtSize.width, y: middleReturnBall.y * courtHeight)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                withAnimation(.easeInOut(duration: 3.0)) {
                    ballPosition = CGPoint(x: rightNet.x * courtSize.width, y: rightNet.y * courtHeight)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [self] in
                let defaultBase = sixTwoBase[rotation]!
                withAnimation(.easeInOut(duration: 1.5)) {
                    for i in 0..<6 {
                        playbackPositions[i] = defaultBase[i]
                    }
                }
                withAnimation { ballVisible = false }
                isPlaying = false
                animationStep = 0
                if isRecording {
                    isRecording = false
                    screenCapture.stopRecording()
                }
            }
            
        default:
            isPlaying = false
            animationStep = 0
            ballVisible = false
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
        
        if isRecording {
            isRecording = false
            screenCapture.stopRecording()
        }
    }
    
    private func goToLibrary() { showLibrary = true }
    
    private func startRecordingAndPlay() {
        screenCapture.startRecording()
        isRecording = true
        runSavedPlay()
    }
    
    private func saveRecordingToCameraRoll() {
        screenCapture.saveToCameraRoll { success, error in
            DispatchQueue.main.async { [self] in
                if success {
                    showSaveRecordingAlert = true
                } else {
                    recordingSaveError = error ?? "Failed to save recording."
                }
            }
        }
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
                .frame(width: 50, height: 50)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 1) {
                Text(role).font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                if let label = label, !label.isEmpty {
                    Text(label).font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 2).padding(.vertical, 1)
                        .background(Color.black.opacity(0.25)).cornerRadius(4)
                }
            }
            
            if isServer {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle().fill(Color(hex: "#ff69b4")).frame(width: 20, height: 20)
                            .overlay(Text("S").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                    }
                    .padding(.trailing, -5).padding(.bottom, -5)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Button(action: onEdit) {
                        Text("⚙️").font(.system(size: 16))
                    }
                    .padding(.leading, -5).padding(.bottom, -5)
                    Spacer()
                }
            }
        }
        .frame(width: 50, height: 50)
        .position(x: position.x, y: position.y)
    }
}

struct EditPlayerView: View {
    @Binding var tempLabel: String
    @Binding var tempLibero: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Name/Number", text: $tempLabel)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Libero").font(.headline).foregroundColor(.primary)
                    Text("Player is in back row (positions 3-5)").font(.caption).foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        Button(action: { tempLibero = true }) {
                            Text("On").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(tempLibero ? Color(hex: "#FFD700") : Color.blue.opacity(0.6))
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { tempLibero = false }) {
                            Text("Off").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(!tempLibero ? Color.gray : Color.gray.opacity(0.4))
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }.foregroundColor(.blue).fontWeight(.bold)
                }
            }
        }
    }
}

struct SavedPlay: Codable {
    let name: String
    let positions: [[CGPoint]]
    let roles: [String]
    let labels: [String?]
    let timestamp: Date
    
    init(name: String, positions: [[CGPoint]], roles: [String], labels: [String?]) {
        self.name = name
        self.positions = positions
        self.roles = roles
        self.labels = labels
        self.timestamp = Date()
    }
}

struct PlayLibraryView: View {
    let onSelect: (SavedPlay) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var savedPlays: [SavedPlay] = []
    private let savedPlaysKey = "SavedVolleyballPlays"
    
    private func loadAllSavedPlays() -> [SavedPlay] {
        guard let data = UserDefaults.standard.data(forKey: savedPlaysKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let plays = try? decoder.decode([SavedPlay].self, from: data) { return plays }
        return []
    }
    
    private func deletePlay(at offsets: IndexSet) {
        savedPlays.remove(atOffsets: offsets)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(savedPlays) {
            UserDefaults.standard.set(data, forKey: savedPlaysKey)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if savedPlays.isEmpty {
                    Text("No saved plays yet.").foregroundColor(.secondary).padding()
                }
                ForEach(savedPlays, id: \.name) { play in
                    Button(action: {
                        onSelect(play)
                        dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(play.name).font(.headline).foregroundColor(.primary)
                            Text("Saved \(play.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deletePlay)
            }
            .navigationTitle("Saved Plays")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            savedPlays = loadAllSavedPlays()
        }
    }
}

extension PlayDesignerView {
    private func persistSavedPlay(_ play: SavedPlay) {
        var savedPlays = loadAllSavedPlays()
        savedPlays.append(play)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(savedPlays) {
            UserDefaults.standard.set(data, forKey: "SavedVolleyballPlays")
        }
    }
    
    private func loadAllSavedPlays() -> [SavedPlay] {
        guard let data = UserDefaults.standard.data(forKey: "SavedVolleyballPlays") else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let plays = try? decoder.decode([SavedPlay].self, from: data) { return plays }
        return []
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
        playName = play.name
        savedPlayerPositions = play.positions
        savedRoles = play.roles
        savedLabels = play.labels
    }
}

#Preview {
    PlayDesignerView()
}
