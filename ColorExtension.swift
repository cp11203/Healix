//
//  ColorExtension.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import SwiftUI

// MARK: - Color Extension
extension Color {
    // App theme colors based on the provided design
    static let healixBlue = Color(red: 0.27, green: 0.51, blue: 0.76)
    static let healixDarkBlue = Color(red: 0.15, green: 0.23, blue: 0.54)
    static let healixRed = Color(red: 0.94, green: 0.42, blue: 0.40)
    static let healixGreen = Color(red: 0.60, green: 0.87, blue: 0.44)
    static let healixLightBlue = Color(red: 0.67, green: 0.80, blue: 0.93)
    static let healixOrange = Color(red: 0.95, green: 0.55, blue: 0.22)
    
    // Background colors
    static let healixBackground = Color(red: 0.97, green: 0.97, blue: 0.97)
    
    // Text colors
    static let healixTextPrimary = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let healixTextSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
}

// MARK: - Gradient Extension
extension LinearGradient {
    // App theme gradients
    static let healixPrimaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color.healixBlue, Color.healixDarkBlue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let healixSecondaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color.healixGreen, Color.healixBlue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
