import SwiftUI

struct CardView: View {
    let moduleId: Int
    @StateObject private var viewModel: CardViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: CardViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                SLoading()
            } else if let error = viewModel.errorMessage {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if let card = viewModel.card {
                ScrollView {
                    VStack(spacing: 28) {
                        // Card visual with glassmorphism
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: card.PrimaryColor ?? "#1E88E5"),
                                            Color(hex: card.PrimaryColor ?? "#1E88E5").opacity(0.6),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 210)
                                .shadow(color: Color(hex: card.PrimaryColor ?? "#1E88E5").opacity(0.35), radius: 20, y: 10)

                            // Decorative circles
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 180)
                                .offset(x: 90, y: -50)
                            Circle()
                                .fill(.white.opacity(0.06))
                                .frame(width: 120)
                                .offset(x: -80, y: 60)

                            VStack(spacing: 18) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white.opacity(0.6))
                                if let number = card.CardNumber {
                                    Text(number)
                                        .font(.title2.monospaced().bold())
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                }
                                if let email = card.Email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 20)

                        if card.CardNumber != nil {
                            // QR Code section
                            VStack(spacing: 12) {
                                Text("Scan to verify")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)

                                Image(systemName: "qrcode")
                                    .font(.system(size: 100))
                                    .foregroundStyle(.primary)
                                    .padding(20)
                                    .background {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color(.systemGray5), lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                SEmptyState(icon: "creditcard", message: "No card available")
            }
        }
        .navigationTitle("Card")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }
}
