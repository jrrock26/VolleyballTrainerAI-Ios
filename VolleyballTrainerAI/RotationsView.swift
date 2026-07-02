import SwiftUI

struct RotationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rotation = 1
    @State private var formation = "6-2"
    @State private var selectedPlayer: String?
    @State private var jerseys: [String: String] = [:]
    @State private var editLabel: String?
    @State private var editValue = ""
    @State private var showInstructions = false
    @State private var selectedBall: String?
    @State private var showServeBall = false
    
    @State private var playerPositions: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var serveBallPosition: CGPoint = .zero
    @State private var returnBallPosition: CGPoint = .zero
    
    @State private var ballAnimationActive = false
    @State private var serveAnimationActive = false
    @State private var animationTask: Task<Void, Never>?
    
    private let courtHeight: CGFloat
    private let width: CGFloat
    
    init() {
        let w = UIScreen.main.bounds.width
        self.width = w
        self.courtHeight = w * 1.4
    }
    
    // Formation data
    let sixTwo: [Int: (labels: [String], base: [[String: Double]], receive: [[String: Double]], defense: [String: [[String: Double]]])] = [
        1: (
            labels: ["S2", "M1", "O2", "O1", "M2", "S1"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.60], ["x": 0.31, "y": 0.57], ["x": 0.72, "y": 0.80],
                ["x": 0.20, "y": 0.85], ["x": 0.47, "y": 0.85], ["x": 0.80, "y": 0.95]
            ],
            defense: ["right": [
                ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55], ["x": 0.25, "y": 0.70],
                ["x": 0.20, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.80, "y": 0.74]
            ], "middle": [
                ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55], ["x": 0.24, "y": 0.70],
                ["x": 0.27, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85]
            ], "left": [
                ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55],
                ["x": 0.15, "y": 0.80], ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85]
            ]]
        ),
        2: (
            labels: ["O1", "S2", "M1", "M2", "S1", "O2"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.85], ["x": 0.50, "y": 0.60], ["x": 0.65, "y": 0.55],
                ["x": 0.45, "y": 0.90], ["x": 0.55, "y": 0.73], ["x": 0.75, "y": 0.90]
            ],
            defense: ["right": [
                ["x": 0.20, "y": 0.65], ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.80, "y": 0.74], ["x": 0.20, "y": 0.75]
            ], "middle": [
                ["x": 0.24, "y": 0.70], ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.27, "y": 0.85]
            ], "left": [
                ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55],
                ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.15, "y": 0.80]
            ]]
        ),
        3: (
            labels: ["M2", "O1", "S2", "S1", "O2", "M1"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.60], ["x": 0.35, "y": 0.85], ["x": 0.80, "y": 0.58],
                ["x": 0.40, "y": 0.70], ["x": 0.55, "y": 0.85], ["x": 0.70, "y": 0.85]
            ],
            defense: ["right": [
                ["x": 0.72, "y": 0.55], ["x": 0.25, "y": 0.70], ["x": 0.82, "y": 0.55],
                ["x": 0.80, "y": 0.74], ["x": 0.25, "y": 0.85], ["x": 0.46, "y": 0.95]
            ], "middle": [
                ["x": 0.46, "y": 0.55], ["x": 0.20, "y": 0.70], ["x": 0.80, "y": 0.70],
                ["x": 0.70, "y": 0.85], ["x": 0.27, "y": 0.85], ["x": 0.46, "y": 0.95]
            ], "left": [
                ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62],
                ["x": 0.65, "y": 0.80], ["x": 0.12, "y": 0.80], ["x": 0.50, "y": 0.95]
            ]]
        ),
        4: (
            labels: ["S1", "M2", "O1", "O2", "M1", "S2"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.60], ["x": 0.31, "y": 0.57], ["x": 0.72, "y": 0.80],
                ["x": 0.20, "y": 0.85], ["x": 0.47, "y": 0.85], ["x": 0.80, "y": 0.95]
            ],
            defense: ["right": [
                ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55], ["x": 0.22, "y": 0.68],
                ["x": 0.20, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.80, "y": 0.74]
            ], "middle": [
                ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55], ["x": 0.25, "y": 0.70],
                ["x": 0.27, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85]
            ], "left": [
                ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55],
                ["x": 0.15, "y": 0.80], ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85]
            ]]
        ),
        5: (
            labels: ["O2", "S1", "M2", "M1", "S2", "O1"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.85], ["x": 0.50, "y": 0.60], ["x": 0.65, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.46, "y": 0.70], ["x": 0.72, "y": 0.95]
            ],
            defense: ["right": [
                ["x": 0.22, "y": 0.70], ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55],
                ["x": 0.45, "y": 0.95], ["x": 0.80, "y": 0.74], ["x": 0.18, "y": 0.85]
            ], "middle": [
                ["x": 0.24, "y": 0.70], ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.27, "y": 0.85]
            ], "left": [
                ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55],
                ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.15, "y": 0.80]
            ]]
        ),
        6: (
            labels: ["M1", "O2", "S1", "S2", "O1", "M2"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.12, "y": 0.55], ["x": 0.20, "y": 0.85], ["x": 0.85, "y": 0.55],
                ["x": 0.30, "y": 0.70], ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.95]
            ],
            defense: ["right": [
                ["x": 0.72, "y": 0.55], ["x": 0.25, "y": 0.70], ["x": 0.82, "y": 0.55],
                ["x": 0.80, "y": 0.74], ["x": 0.20, "y": 0.85], ["x": 0.40, "y": 0.95]
            ], "middle": [
                ["x": 0.46, "y": 0.55], ["x": 0.24, "y": 0.70], ["x": 0.70, "y": 0.70],
                ["x": 0.75, "y": 0.85], ["x": 0.30, "y": 0.85], ["x": 0.50, "y": 0.95]
            ], "left": [
                ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62],
                ["x": 0.70, "y": 0.85], ["x": 0.12, "y": 0.80], ["x": 0.50, "y": 0.95]
            ]]
        )
    ]
    
    let fiveOne: [Int: (labels: [String], base: [[String: Double]], receive: [[String: Double]], defense: [String: [[String: Double]]])] = [
        1: (
            labels: ["S2", "M1", "O2", "O1", "M2", "S1"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.60], ["x": 0.31, "y": 0.57], ["x": 0.72, "y": 0.80],
                ["x": 0.20, "y": 0.85], ["x": 0.47, "y": 0.85], ["x": 0.80, "y": 0.95]
            ],
            defense: ["right": [
                ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55], ["x": 0.25, "y": 0.70],
                ["x": 0.20, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.80, "y": 0.74]
            ], "middle": [
                ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55], ["x": 0.24, "y": 0.70],
                ["x": 0.27, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85]
            ], "left": [
                ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55],
                ["x": 0.15, "y": 0.80], ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85]
            ]]
        ),
        2: (
            labels: ["O1", "S2", "M1", "M2", "S1", "O2"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.85], ["x": 0.50, "y": 0.60], ["x": 0.65, "y": 0.55],
                ["x": 0.45, "y": 0.90], ["x": 0.55, "y": 0.73], ["x": 0.75, "y": 0.90]
            ],
            defense: ["right": [
                ["x": 0.20, "y": 0.65], ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.80, "y": 0.74], ["x": 0.20, "y": 0.75]
            ], "middle": [
                ["x": 0.24, "y": 0.70], ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.27, "y": 0.85]
            ], "left": [
                ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55],
                ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.15, "y": 0.80]
            ]]
        ),
        3: (
            labels: ["M2", "O1", "S2", "S1", "O2", "M1"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.60], ["x": 0.35, "y": 0.85], ["x": 0.80, "y": 0.58],
                ["x": 0.40, "y": 0.70], ["x": 0.55, "y": 0.85], ["x": 0.70, "y": 0.85]
            ],
            defense: ["right": [
                ["x": 0.72, "y": 0.55], ["x": 0.25, "y": 0.70], ["x": 0.82, "y": 0.55],
                ["x": 0.80, "y": 0.74], ["x": 0.25, "y": 0.85], ["x": 0.46, "y": 0.95]
            ], "middle": [
                ["x": 0.46, "y": 0.55], ["x": 0.20, "y": 0.70], ["x": 0.80, "y": 0.70],
                ["x": 0.70, "y": 0.85], ["x": 0.27, "y": 0.85], ["x": 0.46, "y": 0.95]
            ], "left": [
                ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62],
                ["x": 0.65, "y": 0.80], ["x": 0.12, "y": 0.80], ["x": 0.50, "y": 0.95]
            ]]
        ),
        4: (
            labels: ["S1", "M2", "O1", "O2", "M1", "S2"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.35, "y": 0.70], ["x": 0.46, "y": 0.55], ["x": 0.55, "y": 0.55],
                ["x": 0.22, "y": 0.85], ["x": 0.46, "y": 0.85], ["x": 0.72, "y": 0.85]
            ],
            defense: ["right": [
                ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55], ["x": 0.25, "y": 0.70],
                ["x": 0.20, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.80, "y": 0.74]
            ], "middle": [
                ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55], ["x": 0.20, "y": 0.70],
                ["x": 0.12, "y": 0.85], ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85]
            ], "left": [
                ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55],
                ["x": 0.15, "y": 0.70], ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85]
            ]]
        ),
        5: (
            labels: ["O2", "S1", "M2", "M1", "S2", "O1"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.20, "y": 0.65], ["x": 0.46, "y": 0.65], ["x": 0.55, "y": 0.55],
                ["x": 0.15, "y": 0.85], ["x": 0.46, "y": 0.85], ["x": 0.75, "y": 0.85]
            ],
            defense: ["right": [
                ["x": 0.25, "y": 0.70], ["x": 0.82, "y": 0.55], ["x": 0.72, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.80, "y": 0.74], ["x": 0.15, "y": 0.85]
            ], "middle": [
                ["x": 0.24, "y": 0.70], ["x": 0.70, "y": 0.70], ["x": 0.46, "y": 0.55],
                ["x": 0.46, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.27, "y": 0.85]
            ], "left": [
                ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62], ["x": 0.22, "y": 0.55],
                ["x": 0.50, "y": 0.95], ["x": 0.70, "y": 0.85], ["x": 0.12, "y": 0.80]
            ]]
        ),
        6: (
            labels: ["M1", "O2", "S1", "S2", "O1", "M2"],
            base: [
                ["x": 0.2, "y": 0.65], ["x": 0.45, "y": 0.65], ["x": 0.7, "y": 0.65],
                ["x": 0.2, "y": 0.9], ["x": 0.45, "y": 0.9], ["x": 0.75, "y": 1.1]
            ],
            receive: [
                ["x": 0.12, "y": 0.55], ["x": 0.20, "y": 0.60], ["x": 0.70, "y": 0.60],
                ["x": 0.20, "y": 0.85], ["x": 0.46, "y": 0.85], ["x": 0.80, "y": 0.85]
            ],
            defense: ["right": [
                ["x": 0.72, "y": 0.55], ["x": 0.25, "y": 0.70], ["x": 0.82, "y": 0.57],
                ["x": 0.70, "y": 0.74], ["x": 0.20, "y": 0.85], ["x": 0.46, "y": 0.95]
            ], "middle": [
                ["x": 0.46, "y": 0.55], ["x": 0.24, "y": 0.70], ["x": 0.70, "y": 0.70],
                ["x": 0.70, "y": 0.85], ["x": 0.20, "y": 0.85], ["x": 0.46, "y": 0.95]
            ], "left": [
                ["x": 0.22, "y": 0.55], ["x": 0.12, "y": 0.55], ["x": 0.65, "y": 0.62],
                ["x": 0.70, "y": 0.85], ["x": 0.12, "y": 0.80], ["x": 0.50, "y": 0.95]
            ]]
        )
    ]
    
    var currentData: (labels: [String], base: [[String: Double]], receive: [[String: Double]], defense: [String: [[String: Double]]]) {
        if formation == "6-2" {
            return sixTwo[rotation]!
        } else {
            return fiveOne[rotation]!
        }
    }
    
    var body: some View {
        NavigationStack {
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
                    
                    // Court content - top part that should NOT move
                    VStack(spacing: 0) {
                        // Back button + instructions at top
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
                        
                        // Formation title
                        Text(formation == "6-2" ? "6–2 Formation" : "5–1 Formation")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3)
                            .padding(.top, 2)
                        
                        // Court area with players and return balls
                        ZStack {
                            // Players
                            ForEach(Array(0..<6), id: \.self) { i in
                                let pos = playerPositions[i]
                                let label = currentData.labels[i]
                                let isMe = selectedPlayer == label
                                let jersey = jerseys[label] ?? ""
                                
                                PlayerBubbleView(
                                    position: CGPoint(x: pos.x + 8, y: pos.y * 1.10),
                                    label: label,
                                    isMe: isMe,
                                    jersey: jersey,
                                    isServer: i == 5,
                                    onTap: { selectedPlayer = isMe ? nil : label },
                                    onEdit: {
                                        editLabel = label
                                        editValue = jersey
                                    }
                                )
                            }
                            
                            // Return ball label
                            Text("Select Left, Middle, or Right for Return")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3)
                                .position(x: geo.size.width / 2, y: geo.size.height * 0.08)
                            
                            // Return ball buttons
                            Circle()
                                .fill(Color(hex: "#ff69b4").opacity(selectedBall == "left" ? 1 : 0.8))
                                .frame(width: 32, height: 32)
                                .shadow(color: selectedBall == "left" ? Color(hex: "#ff69b4") : .clear, radius: 5)
                                .position(x: geo.size.width * 0.2, y: geo.size.height * 0.12)
                                .onTapGesture { selectBall("left") }
                            
                            Circle()
                                .fill(Color(hex: "#ff69b4").opacity(selectedBall == "middle" ? 1 : 0.8))
                                .frame(width: 32, height: 32)
                                .shadow(color: selectedBall == "middle" ? Color(hex: "#ff69b4") : .clear, radius: 5)
                                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.12)
                                .onTapGesture { selectBall("middle") }
                            
                            Circle()
                                .fill(Color(hex: "#ff69b4").opacity(selectedBall == "right" ? 1 : 0.8))
                                .frame(width: 32, height: 32)
                                .shadow(color: selectedBall == "right" ? Color(hex: "#ff69b4") : .clear, radius: 5)
                                .position(x: geo.size.width * 0.8, y: geo.size.height * 0.12)
                                .onTapGesture { selectBall("right") }
                            
                            // Animated serve ball
                            if showServeBall {
                                Image("volleyball")
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                    .position(x: serveBallPosition.x, y: serveBallPosition.y)
                                    .shadow(radius: 3)
                            }
                            
                            // Animated return ball
                            if selectedBall != nil {
                                Image("volleyball")
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                    .position(x: returnBallPosition.x, y: returnBallPosition.y)
                                    .shadow(radius: 3)
                            }
                        }
                        .frame(height: geo.size.height * 0.5)
                        
                        Spacer()
                    }
                    
                }
                .safeAreaInset(edge: .bottom) {
                    HStack(spacing: 8) {
                        Button(action: runReceive) {
                            Text("Run")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        
                        Button(action: rotate) {
                            Text("Rot(R\(rotation))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                        
                        Button(action: { formation = formation == "6-2" ? "5-1" : "6-2" }) {
                            Text(formation)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            updatePlayerPositions(to: currentData.base.map { pos in
                CGPoint(x: CGFloat(pos["x"]!) * width, y: CGFloat(pos["y"]!) * courtHeight)
            })
        }
        .onChange(of: rotation) { _, _ in
            let base = currentData.base.map { pos in
                CGPoint(x: CGFloat(pos["x"]!) * width, y: CGFloat(pos["y"]!) * courtHeight)
            }
            updatePlayerPositions(to: base)
        }
        .onChange(of: formation) { _, _ in
            let base = currentData.base.map { pos in
                CGPoint(x: CGFloat(pos["x"]!) * width, y: CGFloat(pos["y"]!) * courtHeight)
            }
            updatePlayerPositions(to: base)
        }
        .alert("Edit Player Label", isPresented: .constant(editLabel != nil)) {
            TextField("Player Label", text: $editValue)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Save") {
                if let label = editLabel {
                    jerseys[label] = editValue
                }
                editLabel = nil
                editValue = ""
            }
            Button("Cancel") {
                editLabel = nil
                editValue = ""
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("📘 Instructions")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#2b6cb0"))
            
            Text("Select Run to simulate a serve. Select a return ball to simulate a defensive transition.")
            Text("Rotate will rotate players just like they would on the court.")
            Text("Use the formation toggle to switch between 6–2 and 5–1.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#333"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(hex: "#f4f6f8"))
        .cornerRadius(8)
    }
    
    private func updatePlayerPositions(to positions: [CGPoint]) {
        for i in 0..<6 {
            withAnimation(.easeInOut(duration: 0.5)) {
                playerPositions[i] = positions[i]
            }
        }
    }
    
    private func movePlayers(to positions: [[String: Double]], duration: Double = 2.0) {
        let newPositions = positions.map { pos in
            CGPoint(x: CGFloat(pos["x"]!) * width, y: CGFloat(pos["y"]!) * courtHeight)
        }
        for i in 0..<6 {
            withAnimation(.easeInOut(duration: duration)) {
                playerPositions[i] = newPositions[i]
            }
        }
    }
    
    private func resetPlayers() {
        let base = currentData.base.map { pos in
            CGPoint(x: CGFloat(pos["x"]!) * width, y: CGFloat(pos["y"]!) * courtHeight)
        }
        withAnimation(.easeInOut(duration: 1.2)) {
            for i in 0..<6 {
                playerPositions[i] = base[i]
            }
        }
    }
    
    private func runReceive() {
        selectedBall = nil
        movePlayers(to: currentData.receive)
        
        serveBallPosition = CGPoint(x: 0.8 * width, y: 1.1 * courtHeight)
        showServeBall = true
        
        withAnimation(.easeOut(duration: 2.5)) {
            serveBallPosition = CGPoint(x: width * 0.5, y: 125)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showServeBall = false
        }
    }
    
    private func selectBall(_ side: String) {
        selectedBall = side
        let defensePositions = currentData.defense[side]!
        movePlayers(to: defensePositions)
        
        returnBallPosition = CGPoint(x: width * 0.5, y: 125)
        
        let targetX: CGFloat
        switch side {
        case "left": targetX = width * 0.2
        case "middle": targetX = width * 0.5
        default: targetX = width * 0.8
        }
        
        withAnimation(.easeOut(duration: 2.5)) {
            returnBallPosition = CGPoint(x: targetX, y: courtHeight / 1.9)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                selectedBall = nil
                resetPlayers()
            }
        }
    }
    
    private func rotate() {
        rotation = rotation >= 6 ? 1 : rotation + 1
    }
}

struct PlayerBubbleView: View {
    let position: CGPoint
    let label: String
    let isMe: Bool
    let jersey: String
    let isServer: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#2b6cb0"))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isMe ? Color(hex: "#ff69b4") : Color.clear, lineWidth: 3)
                    )
                
                VStack(spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !jersey.isEmpty {
                        Text(jersey)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#2b6cb0"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                
                if isServer {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(hex: "#ff69b4"))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Text("S")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 44, height: 44)
                }
                
                // Gear icon - lower left
                VStack {
                    Spacer()
                    HStack {
                        Button(action: onEdit) {
                            Text("⚙️")
                                .font(.system(size: 16))
                        }
                        .padding(.leading, -6)
                        .padding(.bottom, -6)
                        Spacer()
                    }
                }
                .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .position(x: position.x, y: position.y)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    RotationsView()
}