// The export card floats at the root, above the navigation stack, because it
// is one glass card over the whole stage. Presenting it inside a screen would
// leave the navigation bar drawn on top of it.

import SwiftUI
import Murmur

@main
struct MurmurLabApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var model = LabModel()
    @State private var path = NavigationPath()

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                Gallery()
            }
            .tint(.white)

            if model.isExporting {
                ExportCard()
            }
        }
        .environment(model)
        .preferredColorScheme(.dark)
        .task {
            if let style = Self.launchStyle {
                path.append(style)
            }
            // -openState success arrives a beat after launch so the state
            // CHANGE runs on screen: entries and flashes are only visible on
            // the way into a state, which is the thing a screenshot rig is
            // usually trying to catch.
            if let state = Self.launchState {
                try? await Task.sleep(for: .seconds(1.2))
                model.state = state
            }
            // -openScheme light flips the preview stage, for the same rig.
            if UserDefaults.standard.string(forKey: "openScheme") == "light" {
                model.previewScheme = .light
            }
        }
    }

    private static var launchState: MurmurState? {
        guard let raw = UserDefaults.standard.string(forKey: "openState") else { return nil }
        return MurmurState(rawValue: raw)
    }

    /// `simctl launch <sim> com.krispuckett.MurmurLab -openStyle eddy` opens
    /// that studio directly. UserDefaults reads `-key value` launch arguments
    /// into the argument domain, which is how an agent drives this app without
    /// having to find a cell and tap it.
    private static var launchStyle: MurmurStyle? {
        guard let raw = UserDefaults.standard.string(forKey: "openStyle") else { return nil }
        return MurmurStyle(rawValue: raw)
    }
}
