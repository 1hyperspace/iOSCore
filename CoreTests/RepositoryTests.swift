//
//  StoreTests.swift
//  CoreTests
//
//  Created by 1Hyper Space on 4/20/21.
//

import XCTest
import Combine
@testable import Core

struct DummyStruct: Storable, Equatable {
    static var version: Int = 0

    let name: String
    let age: Int
    var identifier: String = "2"

    enum IndexedFields: CodingKey, CaseIterable {
        case name, age
    }
}

class RepositoryTests: XCTestCase {
    var cancellables: [Cancellable] = []

    func testRepositoryAdd() {
        let repository = Repository<DummyStruct>.new(freshStart: true)

        var dummies: [DummyStruct] = []

        (1...100).forEach {
            let something = DummyStruct(name: "Lucas\($0)", age: $0)
            dummies.append(something)
        }

        let expectationInitialized = XCTestExpectation(description: "DB Initialized")
        let expectationDataAdded = XCTestExpectation(description: "Data Added")
        let expectationCacheAdded = XCTestExpectation(description: "Cache Added")

        cancellables.append(repository
            .$state
            .sink { state in
                guard state.dbExists == true else {
                    return
                }
                expectationInitialized.fulfill()
            })

        cancellables.append(repository
            .$state
            .sink { state in
                print("TOTAL \(state.totalCount)")
                guard state.totalCount == 50 else {
                    return
                }
                expectationDataAdded.fulfill()
            })

        cancellables.append(repository
            .$state
            .sink { state in
                guard state.cachedItems.count == 50 else {
                    return
                }
                expectationCacheAdded.fulfill()
            })

        repository.dispatch(.add(items: dummies))
        let defaultQuery = repository.helpers.modelBuilder.defaultQuery()
        defaultQuery.addFilter(field: .age, expression: "< 51")
        repository.dispatch(.set(query: defaultQuery))

        wait(for: [expectationInitialized, expectationDataAdded, expectationCacheAdded], timeout: 10)
    }

    override func tearDown() {
        cancellables.forEach { $0.cancel() }
    }
}
