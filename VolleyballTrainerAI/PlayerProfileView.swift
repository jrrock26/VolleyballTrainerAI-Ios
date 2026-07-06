import SwiftUI
import PhotosUI

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
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImageData: Data?
    
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
                    VStack(spacing: 16) {
                        // Header with Profile Image and Name
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                ZStack {
                                    if let data = profileImageData,
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 70))
                                            .foregroundColor(Color(hex: "#2b6cb0"))
                                    }
                                    
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "camera.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.white)
                                                .shadow(radius: 4)
                                        }
                                        .padding(.trailing, 8)
                                        .padding(.bottom, 8)
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(hex: "#2b6cb0"), lineWidth: 3))
                            }
                            
                            TextField("Enter your name", text: $athleteName)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#2b6cb0").opacity(0.15))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#2b6cb0").opacity(0.5), lineWidth: 1))
                        }
                        .padding(.top, 20)
                        
                        // Height Section - More Compact
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Height")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                // Feet picker
                                VStack(spacing: 4) {
                                    Picker("Feet", selection: $heightFeet) {
                                        ForEach(4...7, id: \.self) { ft in
                                            Text("\(ft) ft").tag(ft)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 80)
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
                                    .frame(height: 80)
                                    .clipped()
                                }
                            }
                            
                            // Display total
                            let totalInches = Double(heightFeet * 12 + heightInchPart)
                            Text("\(heightFeet)'\(heightInchPart)\" (\(Int(totalInches)) inches)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#2b6cb0"))
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.9))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Skill Level Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Skill Level")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                ForEach(SkillLevel.allCases, id: \.self) { level in
                                    Button(action: { selectedSkillLevel = level }) {
                                        Text(level.rawValue)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(selectedSkillLevel == level ? .white : .gray)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedSkillLevel == level
                                                    ? Color(hex: "#2b6cb0")
                                                    : Color(red: 0.08, green: 0.08, blue: 0.10)
                                            )
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            Text("Mapped to: \(selectedSkillLevel.mappedAthleteLevel.rawValue) training difficulty")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#2b6cb0").opacity(0.8))
                        }
                        .padding()
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.9))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Position Section - Dropdown
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Position")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
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
                                        .foregroundColor(Color(hex: "#2b6cb0"))
                                        .font(.system(size: 14))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.08, green: 0.08, blue: 0.10))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#2b6cb0").opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding()
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.9))
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
                            .background(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.9))
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
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "#2b6cb0"), Color(hex: "#1e4d8c")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                                .shadow(color: Color(hex: "#2b6cb0").opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        
                        // Reset button
                        Button(action: {
                            profileManager.reset()
                            heightFeet = 5
                            heightInchPart = 8
                            athleteName = ""
                            profileImageData = nil
                        }) {
                            Text("Reset Profile")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(Color(hex: "#2b6cb0"))
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .onAppear {
                loadProfile()
            }
            .onChange(of: selectedImage) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profileImageData = data
                    }
                }
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