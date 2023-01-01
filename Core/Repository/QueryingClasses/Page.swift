//
//  Page.swift
//  Core
//
//  Created by 1Hyper Space on 4/15/21.
//

import Foundation

public struct Page: Codable, Equatable {

    let start: Int
    let count: Int

    public init(start: Int = 0, count: Int? = nil) {
        self.start = start
        self.count = count ?? Constants.pageSize
    }

    public var next: Page {
        Page(start: start + self.count, count: self.count)
    }

    public var name: String {
        "Limit \(start) - Count \(count)"
    }

    public var sql: String {
        "LIMIT \(start), \(count)"
    }

    func contains(index: Int) -> Bool {
        return (start...(start+count)).contains(index)
    }
}
