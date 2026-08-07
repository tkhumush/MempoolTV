//
//  DevelopersView.swift
//  memTV
//
//  Developer profiles with async Nostr lifecycle.
//

import SwiftUI

struct DevelopersView: View {
    @StateObject private var nostrService = NostrService()
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private let developers = [Developer.dev1, Developer.dev2]

    @MainActor
    init() {}

    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HStack {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                    .font(.title2)
                    .buttonStyle(.appleTV)

                    Spacer()

                    Text("Developers")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)

                    Spacer()

                    Button {
                        themeManager.toggleTheme()
                    } label: {
                        Image(systemName: themeManager.currentTheme == .dark ? "sun.max.fill" : "moon.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    .buttonStyle(.appleTV)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)

                if let errorMessage = nostrService.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(themeManager.errorColor)
                        .padding()
                }

                HStack {
                    Circle()
                        .fill(nostrService.isConnected ? themeManager.successColor : themeManager.errorColor)
                        .frame(width: 12, height: 12)

                    Text(nostrService.isConnected ? "Connected to Nostr relay" : "Connecting...")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .font(.caption)
                }
                .padding(.bottom, 20)

                HStack(spacing: 60) {
                    DeveloperProfileCard(
                        developer: Developer.dev1,
                        profile: nostrService.profiles[Developer.dev1.publicKeyHex],
                        themeManager: themeManager
                    )

                    DeveloperProfileCard(
                        developer: Developer.dev2,
                        profile: nostrService.profiles[Developer.dev2.publicKeyHex],
                        themeManager: themeManager
                    )
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .task {
            nostrService.connect()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await nostrService.fetchProfiles(for: developers)
        }
        .onDisappear {
            nostrService.disconnect()
        }
    }
}

struct DeveloperProfileCard: View {
    let developer: Developer
    let profile: NostrProfile?
    let themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 20) {
            AsyncImage(url: URL(string: profile?.picture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.secondaryTextColor.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(profile?.displayableName ?? developer.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
                .multilineTextAlignment(.center)

            ScrollView {
                Text(profile?.displayableAbout ?? "Loading profile...")
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 10)
            }
            .frame(maxHeight: 200)

            VStack(spacing: 8) {
                if let website = profile?.website, !website.isEmpty {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(themeManager.accentColor)
                        Text(website)
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }

                if let lud16 = profile?.lud16, !lud16.isEmpty {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(themeManager.warningColor)
                        Text(lud16)
                            .font(.caption)
                            .foregroundColor(themeManager.warningColor)
                    }
                }

                if let nip05 = profile?.nip05, !nip05.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(themeManager.successColor)
                        Text(nip05)
                            .font(.caption)
                            .foregroundColor(themeManager.successColor)
                    }
                }
            }

            VStack(spacing: 4) {
                Text("Nostr Public Key")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)

                Text(developer.npub)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
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
                .fill(themeManager.cardBackgroundColor)
                .stroke(themeManager.cardBorderColor, lineWidth: 1)
        )
    }
}

#Preview {
    DevelopersView()
        .environmentObject(ThemeManager())
}
