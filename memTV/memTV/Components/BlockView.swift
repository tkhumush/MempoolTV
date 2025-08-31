//
//  BlockView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

struct BlockView: View {
    let blockNumber: Int
    let isConfirmed: Bool
    let transactionCount: Int?
    let isSelected: Bool
    let onTap: () -> Void
    
    let width: CGFloat = 160
    let height: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 8) {
            // Triangle pointer when selected
            if isSelected {
                Triangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 15)
                    .offset(y: 5)
            } else {
                Spacer()
                    .frame(height: 20)
            }
            
            // Text-based graphic for the block
            Rectangle()
                .fill(blockColor)
                .frame(width: width, height: height)
                .overlay(
                    VStack(spacing: 4) {
                        Text("\(blockNumber)")
                            .font(.title2)
                            .foregroundColor(.black)
                            .bold()
                        
                        if let txCount = transactionCount {
                            Text("\(txCount) tx")
                                .font(.caption)
                                .foregroundColor(.black)
                                .opacity(0.8)
                        }
                    }
                )
                .cornerRadius(8)
            
            // Status indicator
            Text(isConfirmed ? "Confirmed" : "Mempool")
                .font(.caption2)
                .foregroundColor(isConfirmed ? .yellow : .purple)
                .opacity(0.9)
        }
        .padding(8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    // MARK: - Computed Properties
    
    private var blockColor: Color {
        if isSelected {
            return isConfirmed ? Color.yellow.opacity(0.9) : Color.purple.opacity(0.9)
        }
        return isConfirmed ? Color.yellow : Color.purple
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

#Preview {
    Group {
        BlockView(
            blockNumber: 800000, 
            isConfirmed: true, 
            transactionCount: 2341,
            isSelected: true,
            onTap: {}
        )
        
        BlockView(
            blockNumber: 12345, 
            isConfirmed: false, 
            transactionCount: nil,
            isSelected: false,
            onTap: {}
        )
    }
    .background(Color.black)
}
