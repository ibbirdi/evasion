import SwiftUI

extension View {
    @ViewBuilder
    func oasisGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}

struct GlassSurface<Content: View>: View {
    let tint: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    @ViewBuilder let content: Content

    init(
        tint: Color = .white.opacity(0.04),
        cornerRadius: CGFloat = 28,
        padding: EdgeInsets = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18),
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 16, y: 8)
    }
}

struct CompactGlassPanel<Content: View>: View {
    let maxWidth: CGFloat
    let contentPadding: EdgeInsets
    @ViewBuilder let content: Content

    init(
        maxWidth: CGFloat = 368,
        contentPadding: EdgeInsets = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18),
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(contentPadding)
        .frame(maxWidth: maxWidth)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 28, y: 14)
    }
}
