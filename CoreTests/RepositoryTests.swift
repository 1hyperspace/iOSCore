//
//  StoreTests.swift
//  CoreTests
//
//  Created by 1Hyper Space on 4/20/21.
//

import XCTest
import Combine
@testable import Core

class RepositoryTests: XCTestCase {
    var cancellables: [Cancellable] = []

    func testRepositoryAdd() {
        let repository = Repository<Person>.new(freshStart: true)

        var dummies: [Person] = []

        (1...100).forEach {
            let something = Person(name: "Lucas", age: $0)
            dummies.append(something)
        }

        let expectationInitialized = XCTestExpectation(description: "DB Initialized")
        let expectationDataAdded = XCTestExpectation(description: "Data Added")
        let expectationCacheAdded = XCTestExpectation(description: "Cache Added")

        cancellables.append(repository
            .$state
            .sink { state in
                if state.dbExists == true {
                    expectationInitialized.fulfill()
                }
                if state.totalCount == 100  {
                    expectationDataAdded.fulfill()
                }
                if state.cachedItems.count == 50 {
                    expectationCacheAdded.fulfill()
                }
            })

        repository.dispatch(.add(items: dummies))
        let defaultQuery = repository.helpers.modelBuilder.defaultQuery()
        repository.dispatch(.set(query: defaultQuery))

        wait(for: [expectationInitialized, expectationDataAdded, expectationCacheAdded], timeout: 10)
    }

    override func tearDown() {
        cancellables.forEach { $0.cancel() }
    }
}
