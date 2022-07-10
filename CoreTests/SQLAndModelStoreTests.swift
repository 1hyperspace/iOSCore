//
//  SQLAndModelStore.swift
//  CoreTests
//
//  Created by LL on 7/10/22.
//

import XCTest
import Combine
@testable import Core

class SQLAndModelStoreTests: XCTestCase {
    var sqlStore: SQLStore<Person>!
    var modelBuilder: ModelBuilder<Person>!

    override func setUp() {
        sqlStore = SQLStore<Person>(freshStart: true)
        modelBuilder = ModelBuilder<Person>()
    }
}
