import SwiftUI

struct FriendsView: View {
    @State private var friendsService = FriendsTrackingService()
    @State private var showInviteSheet = false
    @State private var showAddFriend = false
    @State private var newFriendName = ""

    var body: some View {
        NavigationStack {
            List {
                // Shared with me
                if !friendsService.flightsSharedWithMe().isEmpty {
                    Section("Shared with Me") {
                        ForEach(friendsService.flightsSharedWithMe()) { shared in
                            SharedFlightRow(
                                shared: shared,
                                friendName: friendName(for: shared.friendId)
                            )
                        }
                    }
                }

                // My friends
                Section {
                    ForEach(friendsService.friends) { friend in
                        FriendRow(friend: friend)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            friendsService.removeFriend(id: friendsService.friends[index].id)
                        }
                    }

                    Button {
                        showAddFriend = true
                    } label: {
                        Label("Add Friend", systemImage: "person.badge.plus")
                            .foregroundStyle(AppColors.primary)
                    }
                } header: {
                    Text("Friends")
                }

                // Invite section
                Section {
                    Button {
                        showInviteSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(AppColors.primary)
                            VStack(alignment: .leading) {
                                Text("Generate Invite Link")
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("Share a link so friends can track your flights")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .alert("Add Friend", isPresented: $showAddFriend) {
                TextField("Name", text: $newFriendName)
                Button("Add") {
                    if !newFriendName.isEmpty {
                        friendsService.addFriend(Friend(name: newFriendName))
                        newFriendName = ""
                    }
                }
                Button("Cancel", role: .cancel) { newFriendName = "" }
            }
            .sheet(isPresented: $showInviteSheet) {
                InviteLinkSheet(url: friendsService.generateInviteLink())
            }
        }
    }

    private func friendName(for id: String) -> String {
        friendsService.friends.first { $0.id == id }?.name ?? "Unknown"
    }
}

// MARK: - Subviews

struct FriendRow: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(friend.avatarEmoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(AppColors.surfaceElevated)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                Text("Added \(friend.addedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Circle()
                .fill(friend.isActive ? AppColors.onTime : AppColors.textTertiary)
                .frame(width: 8, height: 8)
        }
    }
}

struct SharedFlightRow: View {
    let shared: SharedFlight
    let friendName: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shared.flightNumber)
                    .font(.subheadline.weight(.bold).monospaced())
                    .foregroundStyle(AppColors.textPrimary)
                Text("Shared by \(friendName)")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Text(shared.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}

struct InviteLinkSheet: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary)

                Text("Invite Link Generated")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                if let url {
                    Text(url.absoluteString)
                        .font(.caption.monospaced())
                        .foregroundStyle(AppColors.textSecondary)
                        .padding()
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    if let url {
                        UIPasteboard.general.string = url.absoluteString
                    }
                    dismiss()
                } label: {
                    Text("Copy Link")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding()
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Pickup Countdown View

struct PickupCountdownView: View {
    let pickupInfo: PickupInfo
    @State private var remainingSeconds: TimeInterval

    init(pickupInfo: PickupInfo) {
        self.pickupInfo = pickupInfo
        self._remainingSeconds = State(initialValue: pickupInfo.remainingSeconds)
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(AppColors.primary)
                Text("Pickup Countdown")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
            }

            HStack(spacing: AppSpacing.xl) {
                VStack(spacing: 4) {
                    Text(formattedCountdown)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColors.primary)
                    Text(pickupInfo.isArrived ? "until bags" : "until arrival")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Divider()
                    .frame(height: 50)

                VStack(alignment: .leading, spacing: 8) {
                    if pickupInfo.isArrived {
                        Label("Landed", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColors.onTime)
                    }
                    if let baggage = pickupInfo.baggageClaim {
                        Label("Carousel \(baggage)", systemImage: AppIcons.baggage)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Label(
                        "ETA: \(pickupInfo.estimatedPickupTime.formatted(date: .omitted, time: .shortened))",
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var formattedCountdown: String {
        let minutes = Int(remainingSeconds) / 60
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, mins)
        }
        return String(format: "%d min", mins)
    }
}
