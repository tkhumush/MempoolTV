import SwiftUI

struct DevelopersView: View {
    @StateObject private var nostrService = NostrService()
    @Environment(\.dismiss) private var dismiss
    
    private let developers = [Developer.dev1, Developer.dev2]
    
    var body: some View {
        ZStack {
            // Match app background
            Color(red: 28/255, green: 28/255, blue: 28/255)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.title2)
                    .buttonStyle(.appleTV)
                    
                    Spacer()
                    
                    Text("Developers")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("") { }
                        .opacity(0)
                        .font(.title2)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                
                // Error message
                if let errorMessage = nostrService.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Connection status
                HStack {
                    Circle()
                        .fill(nostrService.isConnected ? .green : .red)
                        .frame(width: 12, height: 12)
                    
                    Text(nostrService.isConnected ? "Connected to Nostr relay" : "Connecting...")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding(.bottom, 20)
                
                // Two-column layout
                HStack(spacing: 60) {
                    // Left column - Dev1
                    DeveloperProfileCard(
                        developer: Developer.dev1,
                        profile: nostrService.profiles[Developer.dev1.publicKeyHex]
                    )
                    
                    // Right column - Dev2
                    DeveloperProfileCard(
                        developer: Developer.dev2,
                        profile: nostrService.profiles[Developer.dev2.publicKeyHex]
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            nostrService.connect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                nostrService.fetchProfiles(for: developers)
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                nostrService.disconnect()
            }
        }
    }
}

struct DeveloperProfileCard: View {
    let developer: Developer
    let profile: NostrProfile?
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile picture
            AsyncImage(url: URL(string: profile?.picture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Name
            Text(profile?.displayableName ?? developer.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // About section
            ScrollView {
                Text(profile?.displayableAbout ?? "Loading profile...")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 10)
            }
            .frame(maxHeight: 200)
            
            // Additional info
            VStack(spacing: 8) {
                if let website = profile?.website, !website.isEmpty {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text(website)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if let lud16 = profile?.lud16, !lud16.isEmpty {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text(lud16)
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                if let nip05 = profile?.nip05, !nip05.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text(nip05)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Nostr info
            VStack(spacing: 4) {
                Text("Nostr Public Key")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(developer.npub)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    DevelopersView()
}