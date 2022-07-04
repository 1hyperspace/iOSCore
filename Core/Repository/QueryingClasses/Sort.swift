//
//  Sort.swift
//  Core
//
//  Created by 1Hyper Space on 4/19/21.
//

import Foundation

public struct Sort: Codable, Equatable {
    public enum Order: String, Codable, Equatable {
        case ascending
        case descending
    }
    
    private let column: String
    private let order: Order

    public init (column: String, order: Order = .ascending) {
        self.column = column
        self.order = order
    }

    public var name: String {
        "Sort by \([column, order.rawValue].joined(separator: ","))"
    }

    public var sql: String {
        "ORDER BY \([column, order.rawValue].joined(separator: ","))"
    }
}
