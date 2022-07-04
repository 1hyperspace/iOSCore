//
//  SQLManager.swift
//  Core
//
//  Created by 1Hyper Space on 4/17/21.
//

import Foundation
import SQLite

class SQLStore<S: Storable> {

    private let db: Connection
    private let builder: ModelBuilder<S>

    public init?(fullPath: URL? = nil,
                 freshStart: Bool = false,
                 builder: ModelBuilder<S> = ModelBuilder<S>()) {

        self.builder = builder
        let fullPath = fullPath ?? FileManager.getDocumentsDirectory().appendingPathComponent(S.versionedName)

        do {
            if freshStart {
                try FileManager.default.removeItem(at: fullPath)
            }
            self.db = try Connection(fullPath.absoluteString)
        } catch {
            print("Error Initializing Class: \(error.localizedDescription)")
            return nil
        }
    }

    public func exists() -> Bool {
        execute(builder.existsSQL())
    }

    public func count() -> Int {
        do {
            return try db.scalar(builder.count())
        } catch let Result.error(message, _, _) {
            print("SQLite Error: \(message)")
            return 0
        } catch {
            print("Unknown error: \(error.localizedDescription)")
            return 0
        }
    }

    public func initializeTables(for item: S) {
        [builder.createSQL(for: item), builder.createFTSSQL(), builder.createRTreeSQL()].forEach { queryString in
            execute(queryString)
        }
    }

    @discardableResult
    public func add(items: [S]) -> Bool {
        do {
            try db.transaction {
                try items.forEach {
                    guard let insert = builder.insertSQL(for: $0) else {
                        print("Error inserting")
                        return
                    }
                    try db.run(insert)
                }
            }
            return true
        } catch let Result.error(message, _, _) {
            print("SQLite Error: \(message)")
            return false
        } catch {
            print("Unknown error: \(error.localizedDescription)")
            return false
        }
    }

    public func loadItems(_ queryString: String) -> [S] {
        print(queryString)
        do {
            let stmt = try db.prepare(queryString)
            return try stmt.prepareRowIterator().map {
                $0[builder.fullObjectData] // TODO: Nasty the public access on var
            }.map {
                try JSONDecoder().decode(S.self, from: $0)
            }
        } catch let Result.error(message, _, _) {
            print("SQLite Error: \(message)")
            return []
        } catch {
            print("Unknown error: \(error.localizedDescription)")
            return []
        }
    }

    @discardableResult
    public func execute(_ queryString: String) -> Bool {
        print(queryString)
        do {
            try db.run(queryString)
            return true
        } catch let Result.error(message, _, _) {
            print("SQLite Error: \(message)")
            return false
        } catch {
            print("Unknown error: \(error.localizedDescription)")
            return false
        }
    }
}
