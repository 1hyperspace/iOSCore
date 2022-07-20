//
//  DataModel.swift
//  Core
//
//  Created by 1Hyper Space on 4/17/21.
//

import Foundation
import SQLite

public typealias Storable = Identifiable & Versionable & Codable & Indexable

public protocol Locatable {
    var location: (Double, Double)? { get }
}

public protocol Auditable {
    var createdAt: Date { get }
    var modifiedAt: Date { get }
    var deletedAt: Date { get }
    var expiresAt: Date { get }
}

public protocol Searchable {
    var ftsString: String { get }
}

public protocol Indexable {
    associatedtype IndexedFields where IndexedFields: CaseIterable, IndexedFields: CodingKey
}

public protocol Versionable {
    static var version: Int { get }
    static var versionedName: String { get }
}

extension Versionable {
    public static var versionedName: String {
        "\(String(describing: self))_\(String(version))"
    }
}
