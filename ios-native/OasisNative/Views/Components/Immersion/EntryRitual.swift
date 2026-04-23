import SwiftUI

/// Choreographed overlay that plays once when the user taps play from a silent state.
/// A gentle full-screen dim, a single line of scene text, then the overlay clears.
///
/// Non-modal: pointer events pass through so the user can still hit pause mid-ritual. The
/// view observes `AppModel.entryRitualTicket`; each increment arms one full run.
struct EntryRitual: View {
    @Environment(AppModel.self) private var model

    @State private var phase: Phase = .hidden
    @State private var runTask: Task<Void, Never>?
    @State private var currentText: String = ""

    private enum Phase {
        case hidden
        case rising
        case holding
        case falling
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .opacity(dimOpacity)
                .ignoresSafeArea()

            Text(currentText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(textOpacity))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 42)
                .scaleEffect(textScale)
        }
        .allowsHitTesting(false)
        .animation(.smooth(duration: 0.6), value: phase)
        .onChange(of: model.entryRitualTicket) { _, _ in
            armRitual()
        }
    }

    private var dimOpacity: Double {
        switch phase {
        case .hidden: return 0
        case .rising, .holding: return 0.34
        case .falling: return 0
        }
    }

    private var textOpacity: Double {
        switch phase {
        case .hidden, .falling: return 0
        case .rising, .holding: return 0.92
        }
    }

    private var textScale: Double {
        switch phase {
        case .hidden, .falling: return 0.98
        case .rising, .holding: return 1.0
        }
    }

    private func armRitual() {
        runTask?.cancel()

        guard let scene = model.currentScene else { return }
        currentText = scene.detailLine ?? scene.placeLine

        runTask = Task {
            await MainActor.run { phase = .rising }

            try? await Task.sleep(for: .milliseconds(1_400))
            guard !Task.isCancelled else { return }
            await MainActor.run { phase = .holding }

            try? await Task.sleep(for: .milliseconds(1_200))
            guard !Task.isCancelled else { return }
            await MainActor.run { phase = .falling }

            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await MainActor.run { phase = .hidden }
        }
    }
}
