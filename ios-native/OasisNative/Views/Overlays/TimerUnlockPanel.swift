import SwiftUI

struct TimerUnlockPanel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private let durations: [Int] = [60, 120]

    var body: some View {
        VStack(spacing: 18) {
            CompactGlassPanel(maxWidth: 420) {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(red: 0.52, green: 0.91, blue: 0.64))

                        Text(L10n.string(L10n.Premium.timerTitle))
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(L10n.string(L10n.Premium.timerSubtitle))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(durations, id: \.self) { duration in
                            Button {
                                dismiss()
                                model.requestPremiumAccess(from: .timer)
                            } label: {
                                Text(L10n.timerOptionLabel(minutes: duration))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.86))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                }
                            }
                            .buttonStyle(PressScaleButtonStyle())
                            .accessibilityIdentifier("timer.unlock.option.\(duration)")
                        }
                    }

                    Text(L10n.string(L10n.Premium.timerIncluded))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.timer.unlock")
    }
}
