//
//  ListingQuery.swift
//  Core
//
//  Created by LL on 1/15/23.
//

import Foundation

public class ListingQuery<S: Storable>: Equatable, Codable {
    private var whereClauses: [String]
    private var sortByClauses: [String]
    public var page: Page?
    private let itemName: String

    internal init(itemName: String) {
        self.itemName = itemName
        self.whereClauses = []
        self.sortByClauses = []
    }

    public static func == (lhs: ListingQuery, rhs: ListingQuery) -> Bool {
        lhs.page == rhs.page && lhs.sql() == rhs.sql()
    }

    @discardableResult
    public func set(page: Page) -> Self {
        self.page = page
        return self
    }

    @discardableResult
    public func addFilter(field: S.IndexedFields, expression: String) -> Self where S: Indexable {
        self.whereClauses.append("\(field.stringValue) \(expression)")
        return self
    }

    @discardableResult
    public func addSort(field: S.IndexedFields, expression: String) -> Self where S: Indexable {
        self.sortByClauses.append("\(field.stringValue) \(expression)")
        return self
    }

    // We break the strong typing so we can keep it flexible to the user of the lib
    public func sql(with page: Page? = nil) -> String {
        let page = page ?? self.page
        var query = "SELECT id, fullObjectData from \(itemName)"
        query += whereClauses.count > 0 ? " WHERE \(whereClauses.joined(separator: " AND "))" : ""
        query += sortByClauses.count > 0 ? " ORDER BY \(sortByClauses.joined(separator: ", "))" : ""
        if let page = page {
            query += " \(page.sql)"
        }
        return query
    }

    var sqlCount: String {
        var query = "SELECT count(id) from \(itemName)"
        query += whereClauses.count > 0 ? " WHERE \(whereClauses.joined(separator: " AND "))" : ""
        return query
    }
}
