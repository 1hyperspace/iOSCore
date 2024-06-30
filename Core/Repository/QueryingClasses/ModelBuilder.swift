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
    private let searchTable = VirtualTable("search_\(S.versionedName)")

    private let id = Expression<Int64>("id")
    private let expiresAt = Expression<Date?>("expiresAt")
    private let createdAt = Expression<Date?>("createdAt")
    private let fullObjectData = Expression<Data>("fullObjectData")
    private let fts = Expression<String?>("fullTextSearch")

    public init() {}

    public func existsSQL() -> String {
        contentTable.exists.asSQL()
    }

    public func defaultQuery() -> Query<S> {
        return Query(itemName: "content_\(S.versionedName)").set(page: Page())
    }

    public func searchQuery() -> Query<S> {
        return Query(itemName: "search_\(S.versionedName)").set(page: Page())
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
            b.column(createdAt, defaultValue: .now)
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

    public func createFTSSQL(for item: S) -> String {
        let config = FTS5Config()
            .column(id, [.unindexed])
            .column(expiresAt, [.unindexed])
            .column(createdAt, [.unindexed])
            .column(fullObjectData, [.unindexed])

        let mirror = Mirror(reflecting: item)

        S.IndexedFields.allCases.forEach { key in
            guard let item = mirror.children.first(where: { $0.label == key.stringValue }), let itemLabel = item.label else {
                print("Couldn't find \(key.stringValue)")
                return
            }

            config.column(itemLabel)
        }

        let createTable = searchTable.create(.FTS5(config))
        let createIndex = "CREATE UNIQUE INDEX idx_\(S.versionedName)_unique_id ON search_\(S.versionedName)(id);"
        return createTable + ";" + createIndex
    }

    public func addItem(_ item: S) -> [String] {
        let setters = settersSQL(for: item)
        return [
            contentTable.insert(or: .ignore, setters).asSQL(),
            searchTable.insert(or: .ignore, setters).asSQL()
        ]
    }

    private func settersSQL(for item: S) -> [Setter] {
        let identifier = Int64(item.id.hashValue)
        var setters: [Setter] = []

        setters.append(id <- identifier)

        if let auditableItem = item as? Expirable {
            setters.append(expiresAt <- auditableItem.expiresAt)
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

        return setters
    }
}
