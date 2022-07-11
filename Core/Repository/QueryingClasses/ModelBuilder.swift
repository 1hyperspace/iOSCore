//
//  Query.swift
//  Core
//
//  Created by 1Hyper Space on 4/12/21.
//

import Foundation
import SQLite

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
        lhs.page == rhs.page && lhs.query == rhs.query
    }

    @discardableResult
    public func set(page: Page) -> Self {
        self.page = page
        return self
    }

    @discardableResult
    public func addFilter(field: S.IndexedFields, expression: String) -> Self {
        self.whereClauses.append("\(field.stringValue) \(expression)")
        return self
    }

    @discardableResult
    public func addSort(field: S.IndexedFields, expression: String) -> Self {
        self.sortByClauses.append("\(field.stringValue) \(expression)")
        return self
    }

    // We break the strong typing so we can keep it flexible to the user of the lib
    var query: String {
        var query = "SELECT fullObjectData from \(itemName)"
        query += whereClauses.count > 0 ? " WHERE \(whereClauses.joined(separator: " AND "))" : ""
        query += sortByClauses.count > 0 ? " ORDER BY \(sortByClauses.joined(separator: ", "))" : ""
        if let page = page {
            query += " \(page.sql)"
        }
        return query
    }

    var countQuery: String {
        var query = "SELECT count(id) from \(itemName)"
        query += whereClauses.count > 0 ? " WHERE \(whereClauses.joined(separator: " AND "))" : ""
        if let page = page {
            query += " \(page.sql)"
        }
        return query
    }
}

public struct AreaExpression {
    let minLat: Expression<Double>
    let maxLat: Expression<Double>
    let minLong: Expression<Double>
    let maxLong: Expression<Double>

    var all: [Expressible] {
        return [minLat, maxLat, minLong, maxLong]
    }
}

// TODO: Querybuilder knows only about the data of S?
public class ModelBuilder<S: Storable> {

    private let contentTable = Table("content_\(S.versionedName)")
    private let locationTable = VirtualTable("location_\(S.versionedName)")
    private let searchTable = VirtualTable("search_\(S.versionedName)")

    private let id = Expression<Int64>("id")
    private let expiresAt = Expression<Date?>("expiresAt")
    private let createdAt = Expression<Date?>("createdAt")
    private let deletedAt = Expression<Date?>("deletedAt")
    private let fullObjectData = Expression<Data>("fullObjectData")
    private let fts = Expression<String?>("fullTextSearch")
    private let areaExpression = AreaExpression(
        minLat: .init("minLat"),
        maxLat: .init("maxLat"),
        minLong: .init("minLong"),
        maxLong: .init("maxLong")
    )

    public init() {}

    public func existsSQL() -> String {
        contentTable.exists.asSQL()
    }

    public func defaultQuery() -> ListingQuery<S> {
        return ListingQuery(itemName: "content_\(S.versionedName)").set(page: Page())
    }

    public func createObjects(stmt: Statement) throws -> [S]{
        return try stmt.prepareRowIterator().map {
            $0[fullObjectData]
        }.map {
            try JSONDecoder().decode(S.self, from: $0)
        }
    }

    public func createSQL(for item: S) -> String {
        let createTable = contentTable.create(block: { b in
            b.column(id, primaryKey: true)
            b.column(expiresAt)
            b.column(createdAt)
            b.column(deletedAt)
            b.column(fullObjectData)

            let mirror = Mirror(reflecting: item)
            S.IndexedFields.allCases.forEach { key in
                guard let item = mirror.children.first(where: { $0.label == key.stringValue }), let itemLabel = item.label else {
                    print("Couldn't find \(key.stringValue)")
                    return
                }

                switch type(of: item.value) {
                case is Int.Type:
                    b.column(Expression<Int?>(itemLabel))
                case is String.Type:
                    b.column(Expression<String?>(itemLabel))
                case is Date.Type:
                    b.column(Expression<Date?>(itemLabel))
                default:
                    break
                }
            }
        })

        return createTable
    }

    public func createFTSSQL() -> String {
        let config = FTS5Config()
            .column(fts)
            .column(expiresAt, [.unindexed])
            .column(createdAt, [.unindexed])
            .column(deletedAt, [.unindexed])
            .column(fullObjectData, [.unindexed])
            .column(id, [.unindexed])
        let createTable = searchTable.create(.FTS5(config))
        return createTable
    }

    public func createRTreeSQL() -> String {
        let module = Module("rtree", [id] + areaExpression.all)
        return locationTable.create(module)
    }

    public func insertSQL(for item: S) -> String? {
        guard let identifier = item.identifier.hashed() else {
            return nil
        }
        var setters: [Setter] = []

        setters.append(id <- identifier)

        if let auditableItem = item as? Auditable {
            setters.append(expiresAt <- auditableItem.expiresAt)
            setters.append(createdAt <- auditableItem.createdAt)
            setters.append(deletedAt <- auditableItem.deletedAt)
        }

        let mirror = Mirror(reflecting: item)
        S.IndexedFields.allCases.forEach { key in
            guard let item = mirror.children.first(where: { $0.label == key.stringValue }), let itemLabel = item.label else {
                print("Couldn't find \(key.stringValue)")
                return
            }

            // TODO: Abstract this
            switch type(of: item.value) {
            case is Int.Type:
                guard let typedItem = item.value as? Int else { return }
                setters.append(Expression<Int?>(itemLabel) <- typedItem)
            case is String.Type:
                guard let typedItem = item.value as? String else { return }
                setters.append(Expression<String?>(itemLabel) <- typedItem)
            case is Date.Type:
                guard let typedItem = item.value as? Date else { return }
                setters.append(Expression<Date?>(itemLabel) <- typedItem)
            default:
                break
            }
        }

        guard let data = try? JSONEncoder().encode(item) else {
            fatalError()
        }

        setters.append(Expression<Data>("fullObjectData") <- data)

        return contentTable.insert(setters).asSQL()
    }

}
