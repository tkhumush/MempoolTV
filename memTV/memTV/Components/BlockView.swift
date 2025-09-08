//
//  BlockView.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

struct FeeInfo {
    let highPriority: Int    // sat/vB (mempool only - deprecated)
    let mediumPriority: Int  // sat/vB (mempool only - deprecated) 
    let lowPriority: Int     // sat/vB (mempool only - deprecated)
    let estimatedMinutes: Int // minutes until confirmation (mempool only)
    let averageFee: Int?     // average fee in block (confirmed only)
    let medianFee: Int?      // median fee in sat/vB (mempool only)
    
    init(highPriority: Int = 0, mediumPriority: Int = 0, lowPriority: Int = 0, estimatedMinutes: Int = 0, averageFee: Int? = nil, medianFee: Int? = nil) {
        self.highPriority = highPriority
        self.mediumPriority = mediumPriority
        self.lowPriority = lowPriority
        self.estimatedMinutes = estimatedMinutes
        self.averageFee = averageFee
        self.medianFee = medianFee
    }
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
                    .fill(Color.gray)
                    .frame(width: 40, height: 20)
                    .offset(y: 1)
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
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .opacity(0.7)
                                    
                                    Text("\(blockNumber)")
                                        .font(.system(size: 25))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    if let avgFee = fees.averageFee {
                                        Text("Avg: \(avgFee)")
                                            .font(.system(size: 17))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                            .padding(.top, 1)
                                        
                                        Text("sat/vB")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black)
                                            .opacity(0.6)
                                    }
                                }
                            } else {
                                // Mempool: show median fee and confirmation time
                                VStack(spacing: 2) {
                                    Text("Median")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .opacity(0.7)
                                    
                                    if let medianFee = fees.medianFee {
                                        Text("\(medianFee)")
                                            .font(.system(size: 30))
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        
                                        Text("sat/vB")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black)
                                            .opacity(0.6)
                                    }
                                    
                                    Text("~\(fees.estimatedMinutes)min")
                                        .font(.system(size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .padding(.top, 4)
                                }
                            }
                        } else {
                            Text("\(blockNumber)")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .bold()
                        }
                    }
                )
                .cornerRadius(8)
        }
        .padding(8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    // MARK: - Computed Properties
    
    private var blockColor: Color {
        if isSelected {
            return isConfirmed ? Color.orange.opacity(0.9) : Color.gray.opacity(0.9)
        }
        return isConfirmed ? Color.orange : Color.gray
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
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
                estimatedMinutes: 8,
                medianFee: 45
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .background(Color.black)
}
