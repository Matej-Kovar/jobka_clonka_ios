import SwiftUI

struct SImageAttachment: Identifiable {
    var id: String {
        if let documentId = documentId {
            return "doc-\(documentId)"
        }
        if let url = documentUrl {
            return url
        }
        return UUID().uuidString
    }
    
    let documentId: Int?
    let documentUrl: String?
    
    init(documentId: Int?, documentUrl: String?) {
        self.documentId = documentId
        self.documentUrl = documentUrl
    }
}

struct SImageView: View {
    let images: [SImageAttachment]
    @State private var showingGallery = false
    
    init(images: [SImageAttachment]) {
        self.images = images
    }

    var body: some View {
        if let first = images.first {
            Button(action: { showingGallery = true }) {
                ZStack(alignment: .topTrailing) {
                    SImageItemView(attachment: first)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    if images.count > 1 {
                        Text("\(images.count)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.background)
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingGallery) {
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        TabView {
                            ForEach(images) { image in
                                SImageItemView(attachment: image)
                                    .padding()
                            }
                        }
                        .tabViewStyle(.page)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingGallery = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .toolbarBackground(.hidden, for: .navigationBar)
                }
            }
        }
    }
}

@MainActor
struct SImageItemView: View {
    let attachment: SImageAttachment
    @State private var imageURL: URL?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .background(Color(.systemGray6))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                    case .failure:
                        Label(L10n.Image_Fail.key, systemImage: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .background(Color(.systemGray6))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Color(.systemGray6))
            } else {
                Label(L10n.Image_URL.key, systemImage: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Color(.systemGray6))
            }
        }
        .task {
            await loadImageURL()
        }
    }

    private func loadImageURL() async {
        isLoading = true

        if let urlString = attachment.documentUrl,
           let url = URL(string: urlString) {
            imageURL = url
            isLoading = false
            return
        }

        if let documentId = attachment.documentId {
            imageURL = await DocumentAPIService.getDocumentImageURL(documentId: documentId)
        }

        isLoading = false
    }
}
