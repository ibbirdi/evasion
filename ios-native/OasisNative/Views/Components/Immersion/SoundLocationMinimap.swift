import MapKit
import SwiftUI

/// Small map rendered inside `SoundDetailSheet` to give each recording a visible place on
/// the globe. Not interactive in v1 — the goal is the visual anchor ("this really came from
/// somewhere"), not navigation. A tap gesture could open MapKit's directions flow later.
///
/// When the channel has no coordinate (or only a country without a documented region), the
/// view collapses to a quiet gradient fallback rather than an empty map surface.
struct SoundLocationMinimap: View {
    let channel: SoundChannel

    @State private var position: MapCameraPosition

    init(channel: SoundChannel) {
        self.channel = channel
        let coordinate = channel.location.coordinate
            ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        // Continental-scale view: we want the user to read "which part of the world is
        // this from" at a glance, not "what street was the mic on". Approximate locations
        // widen further so the pin doesn't imply documentation we don't have.
        let span = channel.location.isApproximate
            ? MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
            : MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        self._position = State(
            initialValue: .region(MKCoordinateRegion(center: coordinate, span: span))
        )
    }

    var body: some View {
        Group {
            if let coordinate = channel.location.coordinate {
                mapView(coordinate: coordinate)
            } else {
                fallback
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(channel.tint.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
    }

    private func mapView(coordinate: CLLocationCoordinate2D) -> some View {
        Map(position: $position, interactionModes: []) {
            Annotation("", coordinate: coordinate, anchor: .bottom) {
                pinGlyph
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .disabled(true)
    }

    /// Pin shaped as a circle stacked on top of a downward-pointing triangle. We
    /// use a `VStack` (not an `.overlay`) so the triangle is part of the pin's
    /// layout frame: combined with `Annotation(anchor: .bottom)`, that puts the
    /// triangle's tip — *not* the circle's bottom edge — exactly on the
    /// coordinate. Without this, the pin visually reads as centered on the
    /// location instead of pointing at it.
    private var pinGlyph: some View {
        VStack(spacing: -1) {
            ZStack {
                Circle()
                    .fill(channel.tint)
                    .shadow(color: channel.tint.opacity(0.45), radius: 8, y: 2)

                Image(systemName: channel.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.86))
            }
            .frame(width: 30, height: 30)

            Triangle()
                .fill(channel.tint)
                .frame(width: 10, height: 8)
        }
    }

    private var fallback: some View {
        // No coordinate on file: render a quiet radial-gradient tile with the region label.
        // The surface is still channel-tinted so the section doesn't go dark.
        ZStack {
            RadialGradient(
                colors: [
                    channel.tint.opacity(0.28),
                    channel.tint.opacity(0.08),
                    .black.opacity(0.32)
                ],
                center: .center,
                startRadius: 6,
                endRadius: 280
            )
            VStack(spacing: 6) {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(channel.location.rowLabel)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private var accessibilityLabel: String {
        if channel.location.isApproximate {
            return "Approximate location: \(channel.location.fullLabel)"
        }
        return "Location: \(channel.location.fullLabel)"
    }
}

/// Minimal downward-pointing triangle used as the pin tail.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
