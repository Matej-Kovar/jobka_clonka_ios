import SwiftUI

struct LicensePlateView: View {
    let moduleId: Int
    @StateObject private var viewModel: LicensePlateViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: LicensePlateViewModel(moduleId: moduleId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "car")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter License Plate")
                        .font(.headline)
                    TextField("e.g. ABC-1234", text: $viewModel.licensePlate)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.allCharacters)
                        .font(.title3.monospaced())
                }

                Button {
                    Task { await viewModel.search() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Search").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.licensePlate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let result = viewModel.result {
                    VStack(spacing: 12) {
                        Divider()
                        Text("Result")
                            .font(.headline)
                        if let name = result.Displayname {
                            Label(name, systemImage: "person")
                        }
                        if let plate = result.LicensePlate {
                            Label(plate, systemImage: "car")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("License Plates")
    }
}
