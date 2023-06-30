//
//  Query.swift
//  Core
//
//  Created by 1Hyper Space on 4/12/21.
//

import Foundation
import SQLite

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

    public init() {}

    public func existsSQL() -> String {
        contentTable.exists.asSQL()
    }

    public func defaultQuery() -> ListingQuery<S> {
        return ListingQuery(itemName: "content_\(S.versionedName)").set(page: Page())
    }

    public func cleanQuery() -> ListingQuery<S> {
        return ListingQuery(itemName: "content_\(S.versionedName)")
            .set(page: Page())
    }

    public func createObjects(stmt: Statement) throws -> [S]{
        return try stmt.prepareRowIterator().map {
            return $0[fullObjectData]
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
        let createTable = searchTable.create(.FTS5(config))
        return createTable
    }

     public func insertSQL(for item: S) -> String? {
        let identifier = Int64(item.id.hashValue)
        var setters: [Setter] = []

        setters.append(id <- identifier)

        if let auditableItem = item as? Auditable {
            setters.append(expiresAt <- auditableItem.expiresAt)
            setters.append(createdAt <- auditableItem.createdAt)
            setters.append(deletedAt <- auditableItem.deletedAt)
        }

        // TODO: Do mirror only for discovery
        // Also store the Expressions in an array
        let mirror = Mirror(reflecting: item)

        S.IndexedFields.allCases.forEach { key in
            guard let item = mirror.children.first(where: { $0.label == key.stringValue }), let itemLabel = item.label else {
                print("Couldn't find \(key.stringValue)")
                return
            }

            switch item.value {
            case let typedItem as Int:
                setters.append(Expression<Int?>(itemLabel) <- typedItem)
            case let typedItem as String:
                setters.append(Expression<String?>(itemLabel) <- typedItem)
            case let typedItem as Date:
                setters.append(Expression<Date?>(itemLabel) <- typedItem)
            default:
                break
            }
        }

        guard let data = try? JSONEncoder().encode(item) else {
            fatalError()
        }

        setters.append(Expression<Data>("fullObjectData") <- data)

        return contentTable.insert(or: .ignore, setters).asSQL()
    }
}
