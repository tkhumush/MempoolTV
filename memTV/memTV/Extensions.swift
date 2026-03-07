//
//  Extensions.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
