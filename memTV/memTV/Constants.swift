//
//  Constants.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation
import CoreGraphics

enum Constants {
    // MARK: - Polling & Timing
    static let pollingInterval: TimeInterval = 60
    static let blockDurationMinutes = 10
    static let blockDisplayCount = 8

    // MARK: - UI Dimensions
    static let blockWidth: CGFloat = 160
    static let blockHeight: CGFloat = 120
    static let appIconSize: CGFloat = 180
    static let triangleWidth: CGFloat = 40
    static let triangleHeight: CGFloat = 20

    // MARK: - Bitcoin Constants
    static let halvingInterval = 210_000
    static let baseSubsidy = 50.0

    static func subsidy(atHeight height: Int) -> Double {
        let halvings = height / halvingInterval
        return halvings < 32 ? baseSubsidy / pow(2.0, Double(halvings)) : 0.0
    }
}
