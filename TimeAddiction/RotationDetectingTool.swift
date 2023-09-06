//
// from: https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation
//

import SwiftUI
import Combine

// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

// MARK: Custom environment value
/// used in ContentView for toolbar updates
private struct LandscapeKey: EnvironmentKey {
    static let defaultValue: Bool = UIDevice.current.orientation.isLandscape
}

extension EnvironmentValues {
    var isLandscape: Bool {
        get { self[LandscapeKey.self] }
        set { self[LandscapeKey.self] = newValue }
    }
}
