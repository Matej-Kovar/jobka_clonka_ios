import SwiftUI

struct MenuTileView: View {
    let item: XMLMenuItem
    let badgeCount: Int
    let isFavorite: Bool

    var tileColor: Color {
        if let tc = item.tileColor {
            return Color(hex: tc.color)
        }
        return JobkaTheme.primary
    }

    var iconName: String {
        switch item.itemType {
        case "PostList": return "newspaper"
        case "SurveyList": return "checklist"
        case "ChatList": return "bubble.left.and.bubble.right"
        case "Contacts": return "person.2"
        case "Settings": return "gearshape"
        case "AboutApp": return "info.circle"
        case "Form": return "doc.text"
        case "Canteen": return "fork.knife"
        case "Stream": return "text.bubble"
        case "Card": return "creditcard"
        case "TrustBox": return "lock.shield"
        case "CustomPage": return "doc.richtext"
        case "LicensePlates": return "car"
        case "Television": return "tv"
        case "Folder": return "folder"
        case "List": return "list.bullet"
        case "Url": return "link"
        default: return "square.grid.2x2"
        }
    }

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(.white)

                    Text(item.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            }
            .overlay(alignment: .topTrailing) {
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: -4, y: 4)
                }
            }
            .overlay(alignment: .topLeading) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .offset(x: 4, y: 4)
                }
            }
            .background(tileColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
