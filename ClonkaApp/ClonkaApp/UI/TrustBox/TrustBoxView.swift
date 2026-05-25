import SwiftUI

struct TrustBoxView: View {
    let moduleId: Int
    @StateObject private var viewModel: TrustBoxViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: TrustBoxViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isSubmitted {
                successView
            } else {
                formView
            }
        }
        .navigationTitle("Trust Box")
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .nonRepeating)
            Text("Message Sent")
                .font(.title2.bold())
            Text("Thank you for your feedback.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Info header
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anonymous Feedback")
                            .font(.headline)
                        Text("Your identity is not shared with anyone.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Message field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Your Message")
                            .font(.subheadline.weight(.semibold))
                        Text("*")
                            .foregroundStyle(.red)
                    }
                    TextEditor(text: $viewModel.body)
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color(.systemGray4), lineWidth: 1)
                        }
                    HStack {
                        Text("Minimum 10 characters")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("\(viewModel.body.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(viewModel.body.count >= 10 ? .green : .secondary)
                    }
                }

                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email (optional)")
                        .font(.subheadline.weight(.semibold))
                    TextField("email@example.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color(.systemGray4), lineWidth: 1)
                        }
                }

                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                            Text("Submit")
                        }
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isValid || viewModel.isSubmitting)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
