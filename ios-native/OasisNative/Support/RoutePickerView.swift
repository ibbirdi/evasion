import AVKit
import SwiftUI

struct RoutePickerView: UIViewRepresentable {
    var tintColor: UIColor = .white
    var activeTintColor: UIColor = UIColor(red: 0.0, green: 1.0, blue: 0.75, alpha: 1.0)

    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        applyConfiguration(to: view)
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        applyConfiguration(to: uiView)
    }

    private func applyConfiguration(to view: AVRoutePickerView) {
        view.tintColor = tintColor
        view.activeTintColor = activeTintColor
        view.backgroundColor = .clear
    }
}
