//
//  ABIItems.swift
//  Core
//
//  Created by LL on 6/24/22.
//

import Foundation

public struct ABIItems: Codable, Equatable {
    var address: String?
    let type: String
    let name: String?
}

extension ABIItems: Identifiable, Indexable, Versionable {
    public static var version: Int = 1
    public enum IndexedFields: CodingKey, CaseIterable {
        case type, name
    }

    public var id: String {
        address! + (name ?? "")
    }
}
