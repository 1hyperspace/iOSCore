//
//  Filter.swift
//  Core
//
//  Created by 1Hyper Space on 4/19/21.
//

import Foundation

// TODO: We might need to do the Filter<Type> for Int, Date, String
public struct Filter: Codable, Equatable {
    private let column: String
    private let value: String

    public init (column: String, value: String) {
        self.column = column
        self.value = value
    }

    public var name: String {
        "Filter by \(column)"
    }

    public var sql: String {
        "WHERE \(column) == \(value)"
    }
}
