import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    let title: String

    init(employeeId: Int?, groupId: Int?, menuItemId: Int?, title: String) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(employeeId: employeeId, groupId: groupId, menuItemId: menuItemId))
        self.title = title
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                SLoading()
            } else if let error = viewModel.errorMessage, viewModel.messages.isEmpty {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let last = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Message input bar
            Divider()
            HStack(spacing: 10) {
                TextField("Message...", text: $viewModel.messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button {
                    Task { await viewModel.send() }
                } label: {
                    if viewModel.isSending {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.body)
                    }
                }
                .frame(width: 36, height: 36)
                .background(
                    viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color(.systemGray5) : Color.accentColor
                )
                .foregroundStyle(
                    viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.secondary : Color.white
                )
                .clipShape(Circle())
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isOut = msg.IsOut ?? false
        HStack(alignment: .bottom, spacing: 6) {
            if isOut { Spacer(minLength: 48) }
            VStack(alignment: isOut ? .trailing : .leading, spacing: 3) {
                if !isOut, let name = msg.displayName {
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                Text(msg.Message ?? "")
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(isOut ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(isOut ? .white : .primary)
                    .clipShape(BubbleShape(isOutgoing: isOut))

                if let sent = msg.Sent {
                    Text(sent, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                }
            }
            if !isOut { Spacer(minLength: 48) }
        }
        .padding(.vertical, 2)
    }
}

// Chat bubble with tail
struct BubbleShape: Shape {
    let isOutgoing: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6
        var path = Path()

        if isOutgoing {
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius),
                style: .continuous
            )
            // Tail
            path.move(to: CGPoint(x: rect.width - tailSize, y: rect.height - 20))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height - 4),
                control: CGPoint(x: rect.width - 2, y: rect.height - 12)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.width - tailSize - 4, y: rect.height),
                control: CGPoint(x: rect.width - tailSize + 2, y: rect.height)
            )
        } else {
            path.addRoundedRect(
                in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius),
                style: .continuous
            )
            // Tail
            path.move(to: CGPoint(x: tailSize, y: rect.height - 20))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height - 4),
                control: CGPoint(x: 2, y: rect.height - 12)
            )
            path.addQuadCurve(
                to: CGPoint(x: tailSize + 4, y: rect.height),
                control: CGPoint(x: tailSize - 2, y: rect.height)
            )
        }

        return path
    }
}
