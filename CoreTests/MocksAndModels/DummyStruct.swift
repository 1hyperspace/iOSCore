//
//  DummyStruct.swift
//  CoreTests
//
//  Created by LL on 7/10/22.
//

import Foundation
@testable import Core

struct Person: Storable, Equatable {
    static var version: Int = 0

    let name: String
    let age: Int
    var id: String {
        "\(name)\(age)"
    }

    enum IndexedFields: IndexableKeys {
        case name, age
    }
}
