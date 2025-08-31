//
//  BlockView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

struct FeeInfo {
    let highPriority: Int    // sat/vB
    let mediumPriority: Int  // sat/vB
    let lowPriority: Int     // sat/vB
    let estimatedMinutes: Int // minutes until confirmation
}

struct BlockView: View {
    let blockNumber: Int
    let isConfirmed: Bool
    let feeInfo: FeeInfo?
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
                    VStack(spacing: 3) {
                        if let fees = feeInfo {
                            VStack(spacing: 1) {
                                Group {
                                    HStack(spacing: 6) {
                                        Text("H:")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Text("\(fees.highPriority)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Text("M:")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Text("\(fees.mediumPriority)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Text("L:")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Text("\(fees.lowPriority)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                Text("sat/vB")
                                    .font(.caption2)
                                    .foregroundColor(.black)
                                    .opacity(0.7)
                                    .padding(.top, 1)
                                
                                if fees.estimatedMinutes > 0 {
                                    Text("~\(fees.estimatedMinutes)min")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding(.top, 2)
                                } else {
                                    Text("Confirmed")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding(.top, 2)
                                }
                            }
                        } else {
                            Text("\(blockNumber)")
                                .font(.caption)
                                .foregroundColor(.black)
                                .bold()
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
            feeInfo: FeeInfo(
                highPriority: 45,
                mediumPriority: 32,
                lowPriority: 18,
                estimatedMinutes: 12
            ),
            isSelected: true,
            onTap: {}
        )
        
        BlockView(
            blockNumber: 12345, 
            isConfirmed: false, 
            feeInfo: FeeInfo(
                highPriority: 52,
                mediumPriority: 28,
                lowPriority: 15,
                estimatedMinutes: 8
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .background(Color.black)
}
