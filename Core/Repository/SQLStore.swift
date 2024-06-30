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

    public init?(fullPath: URL? = nil,
                 freshStart: Bool = false) {

        let fullPath = fullPath ?? FileManager.getDocumentsDirectory().appendingPathComponent(S.versionedName)

        do {
            if freshStart {
                try? FileManager.default.removeItem(at: fullPath)
            }
            self.db = try Connection(fullPath.absoluteString)
            execute("PRAGMA journal_mode=WAL;")
        }
        catch {
            print("Error Initializing Class: \(error.localizedDescription)")
            return nil
        }
    }

    public func scalar<V>(using query: String) -> V? {
        do {
            let binding = try db.scalar(query)
            guard let binding = binding else { return nil }
            return binding as? V // ?? 0
        } catch let Result.error(message, _, _) {
            print("SQLite Error: \(message)")
            return nil
        } catch {
            print("Unknown error: \(error.localizedDescription)")
            return nil
        }
    }

    @discardableResult
    public func transaction(sqlStatements: [String]) -> Bool {
        do {
            try db.transaction {
                try sqlStatements.forEach { insert in
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

    public func prepare(_ query: String) -> Statement? {
        print(query)
        do {
            return try db.prepare(query)
        } catch let Result.error(message, _, _) {
            print("SQLite Error: \(message)")
            return nil
        } catch {
            print("Unknown error: \(error.localizedDescription)")
            return nil
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
