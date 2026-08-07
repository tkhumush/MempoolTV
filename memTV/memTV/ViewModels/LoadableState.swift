//
//  LoadableState.swift
//  memTV
//
//  Shared loading/error/data state for UI sections.
//

import Foundation

enum LoadableState<T>: Equatable where T: Equatable {
    case idle
    case loading
    case loaded(T)
    case failed(String)

    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
