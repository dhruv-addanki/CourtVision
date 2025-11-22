import Foundation

/// Stores calibration geometry while the user adjusts overlays.
@MainActor
final class CalibrationViewModel: ObservableObject {
    @Published var calibration: CourtCalibration
    @Published var selectedTool: CalibrationTool = .rim

    init(calibration: CourtCalibration = CourtCalibration()) {
        self.calibration = calibration
    }

    var isValid: Bool {
        calibration.isValid
    }

    func reset() {
        calibration = CourtCalibration()
    }
}

enum CalibrationTool: String, CaseIterable, Identifiable {
    case rim
    case backboard
    case line

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rim:
            return "Rim"
        case .backboard:
            return "Backboard"
        case .line:
            return "Line"
        }
    }
}
