import SwiftUI

struct MacPresetsSection: View {
    @Environment(AppModel.self) private var model
    @State private var presetName = ""

    var body: some View {
        VStack(spacing: 12) {
            MacPanelSurface {
                VStack(alignment: .leading, spacing: 12) {
                    MacSectionTitle(L10n.Presets.saveSectionTitle, subtitle: L10n.Presets.saveSectionSubtitle)

                    HStack(spacing: 8) {
                        TextField(L10n.string(L10n.Mac.savePresetPlaceholder), text: $presetName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .onSubmit(savePreset)

                        Button {
                            savePreset()
                        } label: {
                            Text(L10n.Presets.saveAction)
                        }
                        .buttonStyle(MacPrimaryButtonStyle())
                    }
                }
            }

            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(model.presets) { preset in
                        MacPresetRow(preset: preset)
                    }
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func savePreset() {
        guard model.savePreset(named: presetName) else { return }
        presetName = ""
    }
}

private struct MacPresetRow: View {
    @Environment(AppModel.self) private var model
    let preset: Preset

    private var isActive: Bool {
        model.currentPresetID == preset.id
    }

    private var locked: Bool {
        model.isPresetLocked(preset)
    }

    var body: some View {
        MacPanelSurface(padding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
            HStack(spacing: 10) {
                Image(systemName: locked ? "lock.fill" : (isActive ? "checkmark.circle.fill" : "bookmark.fill"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(locked ? Color(red: 0.96, green: 0.83, blue: 0.45) : presetTint)
                    .frame(width: 28, height: 28)
                    .background(presetTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: model.presetDisplayName(preset))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)

                    Text(statusText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.44))
                }

                Spacer(minLength: 0)

                Button {
                    model.loadPreset(preset)
                } label: {
                    Text(isActive ? L10n.Presets.statusActive : L10n.Presets.panelTitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isActive ? presetTint : .white.opacity(0.82))
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                if preset.isUser {
                    Button {
                        model.deletePreset(preset)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.45))
                    .help(L10n.string(L10n.Presets.deleteAction))
                }
            }
        }
    }

    private var presetTint: Color {
        if let channel = preset.channels.first(where: { !$0.value.isMuted })?.key {
            return channel.tint
        }
        return SoundChannel.oiseaux.tint
    }

    private var statusText: LocalizedStringResource {
        if isActive {
            return L10n.Presets.statusActive
        }
        if preset.isUser {
            return L10n.Presets.statusSaved
        }
        return L10n.Presets.statusOasis
    }
}
