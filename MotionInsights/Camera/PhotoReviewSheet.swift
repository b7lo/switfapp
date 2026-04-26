import SwiftUI

/// Review sheet shown after capturing a photo.
/// User can confirm (save) or retake (re-open camera).
struct PhotoReviewSheet: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "Use photo",
                                  systemImage: "checkmark.circle.fill",
                                  tone: .primary) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onConfirm()
                        dismiss()
                    }

                    PrimaryButton(title: "Retake",
                                  systemImage: "camera.fill",
                                  tone: .neutral) {
                        onRetake()
                    }
                }
                .padding(16)
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle("Review photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
