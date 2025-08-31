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
    let width: CGFloat = 160
    let height: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 8) {
            // Text-based graphic for the block
            Rectangle()
                .fill(isConfirmed ? Color.yellow : Color.purple)
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
    }
}

#Preview {
    Group {
        BlockView(blockNumber: 800000, isConfirmed: true, transactionCount: 2341)
        BlockView(blockNumber: 12345, isConfirmed: false, transactionCount: nil)
    }
}
