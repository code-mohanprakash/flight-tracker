import SwiftUI

enum FlightStatus: String, Codable, Hashable, CaseIterable {
    case scheduled
    case active
    case landed
    case cancelled
    case diverted
    case incident
    case unknown

    var displayName: String {
        switch self {
        case .scheduled: "Scheduled"
        case .active: "In Air"
        case .landed: "Landed"
        case .cancelled: "Cancelled"
        case .diverted: "Diverted"
        case .incident: "Incident"
        case .unknown: "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .scheduled: AppColors.scheduled
        case .active: AppColors.inAir
        case .landed: AppColors.landed
        case .cancelled: AppColors.cancelled
        case .diverted: AppColors.diverted
        case .incident: AppColors.cancelled
        case .unknown: AppColors.textTertiary
        }
    }

    var iconName: String {
        switch self {
        case .scheduled: AppIcons.scheduled
        case .active: AppIcons.inAir
        case .landed: AppIcons.landed
        case .cancelled: AppIcons.cancelled
        case .diverted: AppIcons.diverted
        case .incident: AppIcons.cancelled
        case .unknown: "questionmark.circle"
        }
    }

    var isActive: Bool {
        self == .active
    }

    var isTerminal: Bool {
        self == .landed || self == .cancelled
    }
}
