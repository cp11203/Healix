//
//  TabButton.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//
import SwiftUI

// MARK: - TabButton
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .healixBlue : .healixTextSecondary)
                
                Rectangle()
                    .fill(isSelected ? Color.healixBlue : Color.clear)
                    .frame(height: 3)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
struct TabButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            TabButton(title: "Selected Tab", isSelected: true, action: {})
            TabButton(title: "Unselected Tab", isSelected: false, action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
