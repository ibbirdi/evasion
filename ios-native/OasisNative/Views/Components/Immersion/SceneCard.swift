import SwiftUI

/// Small transient surface that names the place you're hearing. Appears briefly when the
/// scene changes, then dims to a quiet state so it doesn't compete with the mixer.
///
/// Layout is deliberately minimal: place line + detail line (when available) + local time.
/// Single VoiceOver label combines all three so the card reads as one coherent utterance.
struct SceneCard: View {
    let scene: CurrentScene
    let compactProgress: CGFloat

    @State private var isEmphasized = false
    @State private var emphasisTask: Task<Void, Never>?

    private static let emphasisDuration: Duration = .seconds(4)

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            placeColumn

            if scene.detailLine != nil {
                separator
                detailColumn
            }

            Spacer(minLength: 0)

            timeColumn
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: Capsule())
                .overlay {
                    Capsule()
                        .fill(scene.tint.opacity(isEmphasized ? 0.10 : 0.04))
                }
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    scene.tint.opacity(isEmphasized ? 0.26 : 0.10),
                    lineWidth: 1
                )
        }
        .opacity(opacityForCompactProgress * (isEmphasized ? 1 : 0.62))
        .scaleEffect(0.97 + (isEmphasized ? 0.03 : 0), anchor: .top)
        .animation(.smooth(duration: 0.35), value: isEmphasized)
        .animation(.smooth(duration: 0.22), value: compactProgress)
        .onAppear(perform: emphasize)
        .onChange(of: scene.id) { _, _ in
            emphasize()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var placeColumn: some View {
        Text(scene.placeLine)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.96))
            .lineLimit(1)
    }

    private var separator: some View {
        Circle()
            .fill(Color.white.opacity(0.32))
            .frame(width: 2, height: 2)
            .offset(y: -2)
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let detail = scene.detailLine {
            Text(detail)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(-1)
        }
    }

    private var timeColumn: some View {
        Text(formattedTime)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.58))
            .monospacedDigit()
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: scene.capturedAt)
    }

    private var opacityForCompactProgress: Double {
        // Fades with the brand lockup so a user scrolling into the mixer isn't distracted by
        // a full-opacity card hovering over the content.
        max(0, 1 - (Double(compactProgress) * 2.6))
    }

    private var accessibilityLabel: String {
        var parts = [scene.placeLine]
        if let detail = scene.detailLine {
            parts.append(detail)
        }
        parts.append(formattedTime)
        return parts.joined(separator: ". ")
    }

    private func emphasize() {
        emphasisTask?.cancel()
        isEmphasized = true
        emphasisTask = Task { [id = scene.id] in
            try? await Task.sleep(for: Self.emphasisDuration)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                // Only dim if we're still showing the same scene — a rapid second change
                // keeps the card emphasized.
                guard scene.id == id else { return }
                isEmphasized = false
            }
        }
    }
}
