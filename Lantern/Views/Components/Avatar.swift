import SwiftUI
import UIKit

/// A round photo when there is one, otherwise initials (people) or a species symbol (pets).
struct Avatar: View {
    enum Fallback {
        case initials(String)
        case symbol(String)
    }

    let photoData: Data?
    let fallback: Fallback
    var size: CGFloat = 56
    var tint: Color = Color.glow

    var body: some View {
        Group {
            if let data = photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                switch fallback {
                case .initials(let text):
                    Text(text)
                        .font(size >= 48 ? .headline : .caption.weight(.semibold))
                        .frame(width: size, height: size)
                        .background(tint.opacity(0.22), in: Circle())
                case .symbol(let name):
                    Image(systemName: name)
                        .font(size >= 48 ? .title3 : .footnote)
                        .frame(width: size, height: size)
                        .background(tint.opacity(0.22), in: Circle())
                }
            }
        }
        .overlay(Circle().strokeBorder(tint.opacity(0.6), lineWidth: size >= 48 ? 1.5 : 1))
        .accessibilityHidden(true)
    }
}

extension Person {
    var avatarFallback: Avatar.Fallback { .initials(initials) }
}

extension Pet {
    var avatarSymbol: String { species == .cat ? "cat.fill" : species == .dog ? "dog.fill" : "pawprint.fill" }
}
