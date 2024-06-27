//
//  Querable.swift
//  Core
//
//  Created by LL on 1/15/23.
//

import Foundation

public protocol Querable: Codable {
    func set(page: Page) -> Self
    var page: Page? { get }
    func sql(with page: Page?) -> String
    var sqlCount: String { get }
}

extension Querable where Self: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sql(with: nil) == rhs.sql(with: nil)
    }
}
