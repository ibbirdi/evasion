import SwiftUI

/// Read-only sheet that surfaces the origin of a sound: long name, geographic location,
/// author on freesound.org, and license. Presented when the user taps the identity row
/// of a `SoundRowView`.
struct SoundDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let channel: SoundChannel

    private var location: ChannelLocation { channel.location }
    private var credit: ChannelCredit { channel.credit }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                header
                locationBlock
                creditBlock
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    channel.tint.opacity(0.14),
                    .black.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.sound-detail.container")
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(channel.tint.opacity(0.22))
                .frame(width: 96, height: 96)
                .overlay {
                    Circle()
                        .strokeBorder(channel.tint.opacity(0.45), lineWidth: 1.2)
                }

            Image(systemName: channel.systemImage)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(channel.localizedName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(channel.tint.opacity(0.85))

            Text(channel.localizedLongName)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.98))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var locationBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.fullLabel)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            if location.isApproximate {
                Text(L10n.SoundDetail.approximateLocation)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        }
    }

    private var creditBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.SoundDetail.recordedBy)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.44))

            Text(credit.author)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.96))

            Text("\(L10n.SoundDetail.licensedUnder) \(credit.license.shortLabel) · freesound.org")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
        }
    }

}

extension L10n {
    enum SoundDetail {
        static let recordedBy = LocalizedStringResource(
            "sound.detail.recordedBy",
            defaultValue: "Recorded by",
            bundle: .main,
            comment: "Small label above the author name in the sound detail sheet."
        )

        static let licensedUnder = LocalizedStringResource(
            "sound.detail.licensedUnder",
            defaultValue: "Licensed",
            bundle: .main,
            comment: "Prefix before the license name, followed by the license label and the source site name."
        )

        static let approximateLocation = LocalizedStringResource(
            "sound.detail.approximateLocation",
            defaultValue: "Approximate location",
            bundle: .main,
            comment: "Small note shown below a location when it was inferred rather than documented by the author."
        )
    }
}
