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
    @State private var selectedSkillLevel: SkillLevel = .jrHigh
    @State private var selectedPosition: PlayerPosition = .all
    @State private var athleteName: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.3)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Spacer(minLength: 80)
                        
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.pink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.4))
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        VStack(spacing: 16) {
                            // Header with Name
                            VStack(spacing: 8) {
                                Text("Player Profile")
                                    .font(.title3.bold())
                                    .foregroundColor(.pink)
                                
                                TextField("Enter your name", text: $athleteName)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.pink.opacity(0.3), lineWidth: 1))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 1))
                            
                            // Height Section - More Compact
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Height")
                                    .font(.headline)
                                    .foregroundColor(.pink)
                                
                                HStack(spacing: 12) {
                                    // Feet picker
                                    VStack(spacing: 4) {
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
                                    VStack(spacing: 4) {
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
                                Text("\(heightFeet)'\(heightInchPart)\" (\(Int(totalInches)) inches)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.pink)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 1))
                            
                            // Skill Level Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Skill Level")
                                    .font(.headline)
                                    .foregroundColor(.pink)
                                
                                HStack(spacing: 8) {
                                    ForEach(SkillLevel.allCases, id: \.self) { level in
                                        Button(action: { selectedSkillLevel = level }) {
                                            Text(level.rawValue)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(selectedSkillLevel == level ? .white : .gray)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedSkillLevel == level
                                                        ? Color.pink.opacity(0.8)
                                                        : Color.black.opacity(0.3)
                                                )
                                                .cornerRadius(8)
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedSkillLevel == level ? Color.pink : Color.clear, lineWidth: 1.5))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                Text("Mapped to: \(selectedSkillLevel.mappedAthleteLevel.rawValue) training difficulty")
                                    .font(.caption)
                                    .foregroundColor(.pink.opacity(0.8))
                            }
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 1))
                            
                            // Position Section - Dropdown
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Position")
                                    .font(.headline)
                                    .foregroundColor(.pink)
                                
                                Menu {
                                    ForEach(PlayerPosition.allCases, id: \.self) { pos in
                                        Button(action: { selectedPosition = pos }) {
                                            HStack {
                                                Text(pos.rawValue)
                                                if selectedPosition == pos {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedPosition.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.pink)
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.pink.opacity(0.3), lineWidth: 1))
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 1))
                            
                            // Current profile stats
                            if profileManager.profile.totalHits > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Career Stats")
                                        .font(.headline)
                                        .foregroundColor(.pink)
                                    
                                    HStack {
                                        ProfileStatBox(label: "Hits", value: "\(profileManager.profile.totalHits)", color: .pink)
                                        ProfileStatBox(label: "Sessions", value: "\(profileManager.profile.totalSessions)", color: .pink)
                                        ProfileStatBox(label: "Level", value: profileManager.profile.athleteLevel.rawValue, color: .pink)
                                    }
                                    
                                    HStack {
                                        ProfileStatBox(label: "Best Jump", value: String(format: "%.1f in", profileManager.profile.lifetimeBestJumpHeight), color: .pink)
                                        ProfileStatBox(label: "Best Speed", value: String(format: "%.1f mph", profileManager.profile.lifetimeBestBallSpeed), color: .pink)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 1))
                            }
                            
                            Spacer(minLength: 100)
                            
                            // Save button
                            Button(action: saveProfile) {
                                Text("Save Profile")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(.pink)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            // Reset button
                            Button(action: {
                                profileManager.reset()
                                heightFeet = 5
                                heightInchPart = 8
                                athleteName = ""
                            }) {
                                Text("Reset Profile")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pink.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.clear)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pink.opacity(0.3), lineWidth: 1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        let saved = profileManager.profile
        if saved.heightInches > 0 {
            heightFeet = Int(saved.heightInches) / 12
            heightInchPart = Int(saved.heightInches) % 12
            heightInches = saved.heightInches
        }
        selectedSkillLevel = saved.skillLevel
        selectedPosition = saved.position
        athleteName = saved.athleteName
    }
    
    private func saveProfile() {
        let totalInches = Double(heightFeet * 12 + heightInchPart)
        profileManager.profile.heightInches = totalInches
        profileManager.profile.skillLevel = selectedSkillLevel
        profileManager.profile.position = selectedPosition
        profileManager.profile.athleteName = athleteName.trimmingCharacters(in: .whitespacesAndNewlines)
        profileManager.save()
        dismiss()
    }
}

// MARK: - Profile Stat Box

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