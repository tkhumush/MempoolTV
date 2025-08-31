//
//  BlockView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

struct FeeInfo {
    let highPriority: Int    // sat/vB (mempool only)
    let mediumPriority: Int  // sat/vB (mempool only) 
    let lowPriority: Int     // sat/vB (mempool only)
    let estimatedMinutes: Int // minutes until confirmation (mempool only)
    let averageFee: Int?     // average fee in block (confirmed only)
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
                    VStack(spacing: 2) {
                        if let fees = feeInfo {
                            if isConfirmed {
                                // Confirmed block: show block number and average fee
                                VStack(spacing: 1) {
                                    Text("Block")
                                        .font(.system(size: 9))
                                        .foregroundColor(.black)
                                        .opacity(0.7)
                                    
                                    Text("\(blockNumber)")
                                        .font(.system(size: 14))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    if let avgFee = fees.averageFee {
                                        Text("Avg: \(avgFee)")
                                            .font(.system(size: 9))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                            .padding(.top, 1)
                                        
                                        Text("sat/vB")
                                            .font(.system(size: 8))
                                            .foregroundColor(.black)
                                            .opacity(0.6)
                                    }
                                }
                            } else {
                                // Mempool: show fee priorities and confirmation time
                                VStack(spacing: 0) {
                                    Group {
                                        HStack(spacing: 4) {
                                            Text("H:")
                                                .font(.system(size: 9))
                                                .fontWeight(.bold)
                                                .foregroundColor(.black)
                                            Text("\(fees.highPriority)")
                                                .font(.system(size: 9))
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Text("M:")
                                                .font(.system(size: 9))
                                                .fontWeight(.bold)
                                                .foregroundColor(.black)
                                            Text("\(fees.mediumPriority)")
                                                .font(.system(size: 9))
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Text("L:")
                                                .font(.system(size: 9))
                                                .fontWeight(.bold)
                                                .foregroundColor(.black)
                                            Text("\(fees.lowPriority)")
                                                .font(.system(size: 9))
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                        }
                                    }
                                    
                                    Text("sat/vB")
                                        .font(.system(size: 8))
                                        .foregroundColor(.black)
                                        .opacity(0.6)
                                        .padding(.top, 1)
                                    
                                    Text("~\(fees.estimatedMinutes)min")
                                        .font(.system(size: 9))
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
        // Confirmed block preview
        BlockView(
            blockNumber: 800000, 
            isConfirmed: true, 
            feeInfo: FeeInfo(
                highPriority: 0,
                mediumPriority: 0,
                lowPriority: 0,
                estimatedMinutes: 0,
                averageFee: 42
            ),
            isSelected: true,
            onTap: {}
        )
        
        // Mempool block preview
        BlockView(
            blockNumber: 12345, 
            isConfirmed: false, 
            feeInfo: FeeInfo(
                highPriority: 52,
                mediumPriority: 28,
                lowPriority: 15,
                estimatedMinutes: 8,
                averageFee: nil
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .background(Color.black)
}
