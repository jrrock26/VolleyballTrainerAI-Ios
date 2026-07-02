import SwiftUI

struct PlayLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var savedPlays: [SavedPlay] = []
    @State private var selectedPlay: SavedPlay?
    @State private var showDeleteAlert = false
    @State private var playToDelete: SavedPlay?
    
    var onLoadPlay: ((SavedPlay) -> Void)?
    
    private let savedPlaysKey = "SavedVolleyballPlays"
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Play Library")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                
                // Empty State
                if savedPlays.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Saved Plays")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Create and save plays in the Play Designer to see them here.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color.black)
                } else {
                    // Plays List
                    List {
                        ForEach(savedPlays.sorted { $0.createdAt > $1.createdAt }) { play in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(play.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text(formatDate(play.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onLoadPlay?(play)
                                dismiss()
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    playToDelete = play
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.black)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.black)
        }
        .onAppear {
            loadSavedPlays()
        }
        .alert("Delete Play", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let play = playToDelete {
                    deletePlay(play)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(playToDelete?.name ?? "")'?")
        }
    }
    
    private func loadSavedPlays() {
        guard let data = UserDefaults.standard.data(forKey: savedPlaysKey) else {
            savedPlays = []
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let plays = try? decoder.decode([SavedPlay].self, from: data) {
            savedPlays = plays
        } else {
            savedPlays = []
        }
    }
    
    private func deletePlay(_ play: SavedPlay) {
        savedPlays.removeAll { $0.id == play.id }
        persistSavedPlays()
    }
    
    private func persistSavedPlays() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(savedPlays) {
            UserDefaults.standard.set(data, forKey: savedPlaysKey)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    PlayLibraryView()
}
