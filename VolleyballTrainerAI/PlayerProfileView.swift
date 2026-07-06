import SwiftUI

// MARK: - Profile Manager

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profile: AthleteProfile {
        didSet { save() }
    }
    
    private let profileKey = "AthleteProfileKey"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let saved = try? JSONDecoder().decode(AthleteProfile.self, from: data) {
            self.profile = saved
        } else {
            self.profile = AthleteProfile()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
    
    func reset() {
        profile = AthleteProfile()
    }
}

// MARK: - Player Profile View

struct PlayerProfileView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var heightInches: Double = 0
    @State private var heightFeet: Int = 5
    @State private var heightInchPart: Int = 8
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "#2b6cb0"))
                            
                            Text("Player Profile")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Used to calibrate jump height and personalize coaching")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Height Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Height")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Enter your height to help calibrate jump height measurements. Your standing reach is estimated from height, and jump height is calculated relative to it.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                // Feet picker
                                VStack {
                                    Text("Feet")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("Feet", selection: $heightFeet) {
                                        ForEach(4...7, id: \.self) { ft in
                                            Text("\(ft) ft").tag(ft)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                }
                                
                                // Inches picker
                                VStack {
                                    Text("Inches")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("Inches", selection: $heightInchPart) {
                                        ForEach(0...11, id: \.self) { inch in
                                            Text("\(inch) in").tag(inch)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                }
                            }
                            
                            // Display total
                            let totalInches = Double(heightFeet * 12 + heightInchPart)
                            HStack {
                                Spacer()
                                Text("\(heightFeet)'\(heightInchPart)\" (\(Int(totalInches)) inches)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(hex: "#2b6cb0"))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .padding()
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Calibration Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How it works")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("• Your standing reach is estimated as height × 1.33\n• Jump height = reach height - standing reach\n• This gives more accurate vertical jump measurements\n• Update your height anytime for better calibration")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Current profile stats
                        if profileManager.profile.totalHits > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Career Stats")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    ProfileStatBox(label: "Hits", value: "\(profileManager.profile.totalHits)", color: .blue)
                                    ProfileStatBox(label: "Sessions", value: "\(profileManager.profile.totalSessions)", color: .green)
                                    ProfileStatBox(label: "Level", value: profileManager.profile.athleteLevel.rawValue, color: .orange)
                                }
                                
                                HStack {
                                    ProfileStatBox(label: "Best Jump", value: String(format: "%.1f in", profileManager.profile.lifetimeBestJumpHeight), color: .purple)
                                    ProfileStatBox(label: "Best Speed", value: String(format: "%.1f mph", profileManager.profile.lifetimeBestBallSpeed), color: .red)
                                }
                            }
                            .padding()
                            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Save button
                        Button(action: saveProfile) {
                            Text("Save Profile")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#2b6cb0"))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Reset
                        Button(action: {
                            profileManager.reset()
                            heightFeet = 5
                            heightInchPart = 8
                        }) {
                            Text("Reset Profile")
                                .font(.system(size: 13))
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#2b6cb0"))
                }
            }
            .onAppear {
                loadHeight()
            }
        }
    }
    
    private func loadHeight() {
        let saved = profileManager.profile.heightInches
        if saved > 0 {
            heightFeet = Int(saved) / 12
            heightInchPart = Int(saved) % 12
            heightInches = saved
        }
    }
    
    private func saveProfile() {
        let totalInches = Double(heightFeet * 12 + heightInchPart)
        profileManager.profile.heightInches = totalInches
        profileManager.save()
        dismiss()
    }
}

struct ProfileStatBox: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    PlayerProfileView()
}