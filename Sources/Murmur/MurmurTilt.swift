// Device attitude, for the glass heroes' interior parallax. The body holds
// still and what is inside it shifts, which is what makes the orb read as a
// physical object in the hand rather than a picture of one.
//
// The view never owns this. It takes a plain CGPoint, so a host can drive it
// from here, from a drag gesture, from a lab slider, or from nothing at all.
// Zero is the documented "unavailable" value and is a perfectly good answer.

import Foundation
import SwiftUI

#if canImport(UIKit) && os(iOS)
import UIKit
#endif

#if os(iOS)
import CoreMotion
import Observation

/// Wraps CoreMotion attitude into a smoothed pair of roughly -1...1 values.
///
/// Guarded on `os(iOS)` rather than `canImport(CoreMotion)`: the module also
/// exists on recent macOS for headphone motion, but CMMotionManager does not,
/// so importing is not the question worth asking.
@MainActor
@Observable
public final class MurmurTilt {
    /// Left and right, roughly -1 to 1.
    public private(set) var x: Double = 0
    /// Forward and back, roughly -1 to 1.
    public private(set) var y: Double = 0

    /// Ready to hand straight to MurmurView.
    public var point: CGPoint { CGPoint(x: x, y: y) }

    /// Whether motion is actually running. False on a device with no
    /// gyroscope, in which case x and y stay at zero and the heroes render
    /// exactly as they would with no tilt at all.
    public private(set) var isActive = false

    @ObservationIgnored private let manager = CMMotionManager()
    /// The pose the device was in when tilt started, used as the zero point.
    @ObservationIgnored private var reference: (pitch: Double, roll: Double)?
    @ObservationIgnored private var lastUpdate: Date?

    public init() {}

    /// Begin publishing. Safe to call twice.
    public func start(updatesPerSecond: Double = 30) {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        reference = nil
        lastUpdate = nil
        isActive = true
        manager.deviceMotionUpdateInterval = 1.0 / max(updatesPerSecond, 1)
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            MainActor.assumeIsolated {
                self.ingest(motion.attitude, at: Date.now)
            }
        }
    }

    public func stop() {
        manager.stopDeviceMotionUpdates()
        isActive = false
    }

    deinit {
        manager.stopDeviceMotionUpdates()
    }

    private func ingest(_ attitude: CMAttitude, at now: Date) {
        // Baseline to the pose the device was in when tilt started, so the
        // interior sits still on appear and only a change from that pose
        // moves it. Without this the first sample jumps to the absolute
        // attitude, which reads as the contents sliding then settling.
        if reference == nil {
            reference = (attitude.pitch, attitude.roll)
        }
        let pitch = attitude.pitch - (reference?.pitch ?? 0)
        let roll = attitude.roll - (reference?.roll ?? 0)

        let dt = lastUpdate.map { min(max(now.timeIntervalSince($0), 0), 0.25) }
            ?? Self.smoothing
        lastUpdate = now

        x = Self.approach(x, Self.normalize(roll), dt)
        y = Self.approach(y, Self.normalize(pitch), dt)
    }

    /// Full scale at about 34 degrees, which is roughly as far as a wrist
    /// turns while someone is still looking at the screen. Past that it
    /// clamps rather than running away.
    private static func normalize(_ radians: Double) -> Double {
        min(max(radians / 0.6, -1), 1)
    }

    /// Time constant. Long enough that hand tremor does not reach the glass,
    /// short enough that a deliberate turn feels attached to the device.
    private static let smoothing = 0.12

    private static func approach(_ value: Double, _ target: Double, _ dt: Double) -> Double {
        value + (target - value) * (1 - exp(-dt / smoothing))
    }
}
#endif

// MARK: - Entry haptics

/// Opt-in feedback on state entry. Never on the interpolation: the crossfade
/// is continuous and a haptic is not, so it fires once, when the state is
/// entered, or not at all.
enum MurmurHaptics {
    static func play(entering state: MurmurState) {
        #if canImport(UIKit) && os(iOS)
        switch state {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case .error:
            // Two light ticks rather than the system's error notification,
            // which is a heavy buzz and reads as a failure the person caused.
            // This is the same catch the stutter entry draws.
            tick()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { tick() }
        case .thinking:
            tick()
        case .idle, .listening, .responding:
            // Nothing. These are conditions rather than events, and a device
            // that buzzes every time a microphone opens is a device someone
            // turns off.
            break
        }
        #endif
    }

    #if canImport(UIKit) && os(iOS)
    private static func tick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    #endif
}
