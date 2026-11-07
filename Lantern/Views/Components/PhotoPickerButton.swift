import SwiftUI
import PhotosUI
import UIKit

/// Attach one photo from the library. Stored on-device as external data.
struct PhotoPickerButton: View {
    @Binding var photoData: Data?
    /// Longest side in pixels after import. Nil keeps the picked size (shutoff photos need detail).
    var maxPixels: CGFloat? = nil
    var title: String = "Add a photo"
    @State private var selection: PhotosPickerItem?

    static func scaled(_ image: UIImage, maxPixels: CGFloat?) -> UIImage {
        guard let maxPixels else { return image }
        let longest = max(image.size.width, image.size.height) * image.scale
        guard longest > maxPixels else { return image }
        let ratio = maxPixels / longest
        let target = CGSize(width: image.size.width * image.scale * ratio, height: image.size.height * image.scale * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
    }

    var body: some View {
        HStack {
            if let data = photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
                Button("Remove", role: .destructive) { photoData = nil }
            } else {
                PhotosPicker(selection: $selection, matching: .images) {
                    Label(title, systemImage: "photo")
                }
            }
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let small = PhotoPickerButton.scaled(image, maxPixels: maxPixels).jpegData(compressionQuality: 0.6) {
                    photoData = small
                }
            }
        }
    }
}
