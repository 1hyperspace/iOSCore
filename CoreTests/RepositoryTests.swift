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

    private func generateDummies() -> [Person] {
        var dummies: [Person] = []
        (1...100).forEach {
            let something = Person(name: "Lucas", age: $0)
            dummies.append(something)
        }
        return dummies
    }

    // These are some sort of integration tests, since we're testing several items
    // For example this one, it's testing that not only that the DB is initalized (SQLStore),
    // but also that the state of the repository is being updated (dbExists == true) and also
    func testRepositoryInitialize() {
        let repository = Repository<Person>.new(freshStart: true)

        let dummies = generateDummies()

        let expectationInitialized = XCTestExpectation(description: "DB Initialized")

        cancellables.append(repository
            .$state
            .sink { state in
                if state.dbExists == true {
                    expectationInitialized.fulfill()
                }
            })
        let defaultQuery = repository.helpers.modelBuilder.defaultQuery()
        repository.dispatch(.set(query: defaultQuery))
        repository.dispatch(.add(items: dummies))

        wait(for: [expectationInitialized], timeout: 10)
    }

    func testRepositoryAdd() {
        let repository = Repository<Person>.new(freshStart: true)

        let dummies = generateDummies()

        let expectationDataAdded = XCTestExpectation(description: "Data Added")

        cancellables.append(repository
            .$state
            .sink { state in
                if state.totalCount == 100  {
                    expectationDataAdded.fulfill()
                }
            })
        let defaultQuery = repository.helpers.modelBuilder.defaultQuery()
        repository.dispatch(.set(query: defaultQuery))
        repository.dispatch(.add(items: dummies))
        repository.dispatch(.readingItem(index: 49))

        wait(for: [expectationDataAdded], timeout: 10)
    }

    func testRepositoryCache() {
        let repository = Repository<Person>.new(freshStart: true)
        let dummies = generateDummies()
        let expectationCacheAdded = XCTestExpectation(description: "Cache Added")

        cancellables.append(repository
            .$state
            .sink { state in
                if state.cachedItems.count == 50 {
                    expectationCacheAdded.fulfill()
                }
            })
        let defaultQuery = repository.helpers.modelBuilder.defaultQuery()
        repository.dispatch(.set(query: defaultQuery))
        repository.dispatch(.add(items: dummies))

        wait(for: [expectationCacheAdded], timeout: 10)
    }

    func testRepositoryReadingItem() {
        let repository = Repository<Person>.new(freshStart: true)
        let dummies = generateDummies()
        let expectationCacheAdded = XCTestExpectation(description: "Cache Added")

        cancellables.append(repository
            .$state
            .sink { state in
                if state.cachedItems.count == 75 {
                    expectationCacheAdded.fulfill()
                }
            })
        let defaultQuery = repository.helpers.modelBuilder.defaultQuery()
        repository.dispatch(.set(query: defaultQuery))
        repository.dispatch(.add(items: dummies))
        repository.dispatch(.readingItem(index: 49))

        wait(for: [expectationCacheAdded], timeout: 10)
    }

    override func tearDown() {
        cancellables.forEach { $0.cancel() }
    }
}
