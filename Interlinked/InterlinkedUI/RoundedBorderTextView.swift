//
//  ImageWithTextView.swift
//  InterlinkedUI
//
//  Created by Dominik Kowalski on 24/05/2023.
//

import Foundation
import SwiftUI
import AppKit

struct RoundedBorderTextView: View {
    let content: String
    let description: String
    @Binding var selected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(content)
                .font(.caption)
                .foregroundColor(selected ? .primary : .secondary)
                .padding()
                .frame(width: 175, height: 200)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(selected ? Color.accentColor : .secondary, lineWidth: selected ? 3 : 2)
                )
                .contentShape(Rectangle())
                .animation(.linear(duration: 0.2), value: selected)
                .onTapGesture {
                    selected.toggle()
                }

            Text(description)
                .font(.caption)
                .foregroundColor(selected ? .primary : .secondary)
                .animation(.linear(duration: 0.2), value: selected)
        }
    }
}
