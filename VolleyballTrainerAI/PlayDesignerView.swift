import SwiftUI

struct PlayDesignerView: View {
    @Environment(\.dismiss) private var dismiss
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
    
    @State private var showRecordPrompt = false
    @State private var saveModalVisible = false
    @State private var playName = ""
    @State private var validationVisible = false
    
    @State private var ballPosition: CGPoint = .zero
    @State private var ballVisible = false
    @State private var spin: Angle = .zero
    
    @State private var showInstructions = false
    
    private let width = UIScreen.main.bounds.width
    private let courtHeight: CGFloat = UIScreen.main.bounds.width * 1.1
    
    enum FormationMode: String {
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
            CGPoint(x: 0.2, y: 0.55), CGPoint(x: 0.45, y: 0.55), CGPoint(x: 0.68, y: 0.55),
            CGPoint(x: 0.2, y: 0.8), CGPoint(x: 0.45, y: 0.8), CGPoint(x: 0.68, y: 0.8)
        ],
        2: [
            CGPoint(x: 0.2, y: 0.55), CGPoint(x: 0.45, y: 0.55), CGPoint(x: 0.68, y: 0.55),
            CGPoint(x: 0.2, y: 0.8), CGPoint(x: 0.45, y: 0.8), CGPoint(x: 0.68, y: 0.8)
        ],
        3: [
            CGPoint(x: 0.2, y: 0.55), CGPoint(x: 0.45, y: 0.55), CGPoint(x: 0.68, y: 0.55),
            CGPoint(x: 0.2, y: 0.8), CGPoint(x: 0.45, y: 0.8), CGPoint(x: 0.68, y: 0.8)
        ],
        4: [
            CGPoint(x: 0.2, y: 0.55), CGPoint(x: 0.45, y: 0.55), CGPoint(x: 0.68, y: 0.55),
            CGPoint(x: 0.2, y: 0.8), CGPoint(x: 0.45, y: 0.8), CGPoint(x: 0.68, y: 0.8)
        ],
        5: [
            CGPoint(x: 0.2, y: 0.55), CGPoint(x: 0.45, y: 0.55), CGPoint(x: 0.68, y: 0.55),
            CGPoint(x: 0.2, y: 0.8), CGPoint(x: 0.45, y: 0.8), CGPoint(x: 0.68, y: 0.8)
        ],
        6: [
            CGPoint(x: 0.2, y: 0.55), CGPoint(x: 0.45, y: 0.55), CGPoint(x: 0.68, y: 0.55),
            CGPoint(x: 0.2, y: 0.8), CGPoint(x: 0.45, y: 0.8), CGPoint(x: 0.68, y: 0.8)
        ]
    ]
    
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
                    // Back button
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
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    
                    // Step label
                    Text(stepLabels[stepIndex])
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3)
                        .padding(.top, 2)
                    
                    // Go to next step button
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
                    
                    // Player area fills remaining space
                    ZStack {
                        // Players
                        ForEach(Array(0..<6), id: \.self) { i in
                            let pos = currentPositions[i]
                            let role = playerRoles[i]
                            let label = playerLabels[i]
                            let isLibero = role == "L"
                            
                            PlayDesignerPlayerView(
                                position: CGPoint(x: pos.x, y: pos.y * 1.45),
                                role: role,
                                label: label,
                                isLibero: isLibero,
                                isServer: i == 5
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let newX = max(0, min(1, value.location.x / geo.size.width))
                                        let newY = max(0, min(1, value.location.y / geo.size.height))
                                        updatePosition(at: i, to: CGPoint(x: newX, y: newY))
                                    }
                            )
                        }
                        
                        // Return ball indicators
                        Circle()
                            .fill(Color(hex: "#ff69b4").opacity(mode == .defendLeft ? 1 : 0.3))
                            .frame(width: 32, height: 32)
                            .shadow(color: Color(hex: "#ff69b4"), radius: mode == .defendLeft ? 6 : 0)
                            .position(x: geo.size.width * 0.2, y: geo.size.height * 0.10)
                        
                        Circle()
                            .fill(Color(hex: "#ff69b4").opacity(mode == .defendMiddle ? 1 : 0.3))
                            .frame(width: 32, height: 32)
                            .shadow(color: Color(hex: "#ff69b4"), radius: mode == .defendMiddle ? 6 : 0)
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.10)
                        
                        Circle()
                            .fill(Color(hex: "#ff69b4").opacity(mode == .defendRight ? 1 : 0.3))
                            .frame(width: 32, height: 32)
                            .shadow(color: Color(hex: "#ff69b4"), radius: mode == .defendRight ? 6 : 0)
                            .position(x: geo.size.width * 0.8, y: geo.size.height * 0.10)
                        
                        // Animated ball
                        if ballVisible {
                            Image("volleyball")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .position(x: ballPosition.x, y: ballPosition.y)
                                .shadow(radius: 3)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    Spacer().frame(height: geo.size.height * 0.05)
                    
                    // Bottom controls - compact
                    HStack(spacing: 6) {
                        Button(action: { showRecordPrompt = true }) {
                            Text("Run")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        
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
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                initializePositions()
            }
            .onChange(of: rotation) { _, _ in
                initializePositions()
            }
            .alert("Edit Player Label", isPresented: .constant(selectedPlayerIndex != nil && roleModalVisible)) {
                TextField("Player Label", text: $tempLabel)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Save") {
                    if let index = selectedPlayerIndex {
                        playerLabels[index] = tempLabel.isEmpty ? nil : tempLabel
                    }
                    tempLabel = ""
                    selectedPlayerIndex = nil
                    roleModalVisible = false
                }
                Button("Cancel") {
                    tempLabel = ""
                    selectedPlayerIndex = nil
                    roleModalVisible = false
                }
            }
            .alert("Player Settings", isPresented: .constant(roleModalVisible && selectedPlayerIndex == nil)) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $saveModalVisible) {
                saveModalView
            }
            .alert("Incomplete Play", isPresented: $validationVisible) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please complete all 5 formation steps before saving.")
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📘 Instructions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#2b6cb0"))
                Spacer()
                Button("Hide") {
                    showInstructions = false
                }
                .foregroundColor(Color(hex: "#888"))
                .font(.system(size: 14, weight: .semibold))
            }
            .padding(.bottom, 6)
            
            Text("Drag and drop players to desired positions for each step.")
            Text("Step 1: Set Pre‑Serve Formation.")
            Text("Step 2: Set Active Serve Formation.")
            Text("Steps 3–5: Set Left, Middle, Right Return formations.")
            Text("Use the gear icon to change player roles and assign initials or jersey #.")
            Text("Use the Rotate button to rotate the formation clockwise.")
            Text("Save stores the full play (all 5 formations) for this rotation.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#333"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(hex: "#f4f6f8"))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        let newRotation = rotation >= 6 ? 1 : rotation + 1
        rotation = newRotation
        
        var roles = playerRoles
        var labels = playerLabels
        
        let liberoIndex = roles.firstIndex(of: "L")
        var liberoLabel: String? = nil
        
        if let idx = liberoIndex {
            liberoLabel = labels[idx]
            roles.remove(at: idx)
            labels.remove(at: idx)
        }
        
        let clockwiseOrder = [5, 4, 3, 0, 1, 2]
        let orderedRoles = clockwiseOrder.map { roles[$0] }
        let orderedLabels = clockwiseOrder.map { labels[$0] }
        
        var newRoles = orderedRoles
        var newLabels = orderedLabels
        newRoles.removeLast()
        newRoles.insert(newRoles.removeFirst(), at: 0)
        newLabels.removeLast()
        newLabels.insert(newLabels.removeFirst(), at: 0)
        
        clockwiseOrder.enumerated().forEach { pos, idx in
            roles[pos] = newRoles[idx]
            labels[pos] = newLabels[idx]
        }
        
        if let idx = liberoIndex {
            let safeIndex = max(3, min(5, idx))
            roles[safeIndex] = "L"
            labels[safeIndex] = liberoLabel
        }
        
        playerRoles = roles
        playerLabels = labels
    }
    
    private func goToNextStep() {
        if stepIndex < 4 {
            stepIndex += 1
            mode = FormationMode(rawValue: [
                "preServe", "activeServe", "defendLeft", "defendMiddle", "defendRight"
            ][stepIndex])!
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
        
        saveModalVisible = false
    }
    
    private func goToLibrary() {
    }
    
    private func resetPlay() {
        initializePositions()
        playerRoles = ["OH", "MB", "OPP", "S", "MB", "OH"]
        playerLabels = [nil, nil, nil, nil, nil, nil]
    }
    
    private func runPlay() {
        let base = sixTwoBase[rotation]!
        
        preServePositions = base
        activeServePositions = base
        defendLeftPositions = base
        defendMiddlePositions = base
        defendRightPositions = base
        
        ballPosition = CGPoint(x: 0.5 * width, y: 50)
        ballVisible = true
        
        withAnimation(.easeInOut(duration: 3.0)) {
            ballPosition = CGPoint(x: width * 0.5, y: courtHeight * 0.3)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 2.0)) {
                ballVisible = false
            }
        }
    }
}

struct PlayDesignerPlayerView: View {
    let position: CGPoint
    let role: String
    let label: String?
    let isLibero: Bool
    let isServer: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isLibero ? Color(hex: "#FFD700") : Color(hex: "#2b6cb0"))
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            Text(role)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
            
            if let label = label, !label.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#2b6cb0"))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .padding(.trailing, -3)
                    .padding(.bottom, -3)
                }
                .frame(width: 40, height: 40)
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
                    .padding(.trailing, -3)
                    .padding(.bottom, -3)
                }
                .frame(width: 40, height: 40)
            }
        }
        .position(x: position.x * UIScreen.main.bounds.width, y: position.y * (UIScreen.main.bounds.width * 1.1))
    }
}

#Preview {
    PlayDesignerView()
}