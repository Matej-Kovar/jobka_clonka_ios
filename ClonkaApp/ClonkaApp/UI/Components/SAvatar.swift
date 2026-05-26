import SwiftUI

struct SAvatar: View {
    let initials: String?
    let color: String?
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: color ?? "#666"))
                .frame(width: size, height: size)
            Text(initials ?? "?")
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
