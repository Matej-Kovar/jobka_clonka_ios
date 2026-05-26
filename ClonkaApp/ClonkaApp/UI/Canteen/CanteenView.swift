import SwiftUI

struct CanteenView: View {
    let moduleId: Int
    @StateObject private var viewModel: CanteenViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: CanteenViewModel(moduleId: moduleId))
    }

    var body: some View {
        canteenContent
            .navigationTitle("Canteen")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var canteenContent: some View {
        if viewModel.isLoading && viewModel.canteens.isEmpty {
            SLoading()
        } else if let error = viewModel.errorMessage, viewModel.canteens.isEmpty {
            SErrorState(message: error) { Task { await viewModel.load() } }
        } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.canteens.count > 1 {
                            Picker("Canteen", selection: $viewModel.selectedCanteen) {
                                ForEach(viewModel.canteens) { canteen in
                                    Text(canteen.DisplayName ?? "Canteen \(canteen.ID)")
                                        .tag(canteen as CanteenItem?)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }

                        // Date picker
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.accentColor)
                            DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                        .onChange(of: viewModel.selectedDate) { _ in
                            Task { await viewModel.loadMenu() }
                        }

                        if viewModel.isLoadingMenu {
                            SLoading(message: "Loading menu...")
                                .frame(height: 200)
                        } else if viewModel.slots.isEmpty {
                            SEmptyState(icon: "fork.knife", message: "No menu available for this date")
                                .frame(height: 200)
                        } else {
                            ForEach(viewModel.slots) { slot in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(slot.DisplayName ?? "Menu")
                                        .font(.headline)
                                        .padding(.horizontal, 16)

                                    ForEach(slot.Sections ?? []) { section in
                                        VStack(alignment: .leading, spacing: 8) {
                                            if let name = section.DisplayName, !name.isEmpty {
                                                Text(name)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                                    .padding(.horizontal, 16)
                                            }

                                            ForEach(section.Choices ?? []) { choice in
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(choice.DisplayName ?? "")
                                                            .font(.body)
                                                        if let desc = choice.Description, !desc.isEmpty {
                                                            Text(desc)
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                        }
                                                    }
                                                    Spacer()
                                                    if let price = choice.FullPrice {
                                                        Text(String(format: "%.2f", price))
                                                            .font(.callout.bold().monospacedDigit())
                                                            .foregroundStyle(Color.accentColor)
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 6)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Color(.systemGray5), lineWidth: 1)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
    }
