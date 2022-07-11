//
//  RepositoryTests.swift
//  CoreTests
//
//  Created by 1Hyper Space on 4/12/21.
//

import XCTest
@testable import Core

class PageHelperTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testNegativeRanges() {

        XCTAssertEqual(
            PageHelper().calculatePage(index: 0, current: Page(start: -10, count: 20)),
            .failure(.negativeRange)
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: -1, current: Page(start: 0, count: 2)),
            .failure(.negativeIndex)
        )
    }

    func testWithinRanges() {

        XCTAssertEqual(
            PageHelper().calculatePage(index: 500, current: Page(start: 250, count: 500)),
            .success(.noChangeNeeded)
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 1, current: Page(start: 0, count: 2)),
            .success(.suggested(page:  Page(start: 0, count: Constants.pageSize)))
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 26, current: Page(start: 0, count: 60)),
            .success(.noChangeNeeded)
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 70, current: Page(start: 0, count: 80)),
            .success(.suggested(page: Page(start: 20, count: Constants.pageSize * 2)))
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 70, current: Page(start: 0, count: 80)),
            .success(.suggested(page: Page(start: 20, count: Constants.pageSize * 2)))
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 49, current: Page(start: 0, count: 50)),
            .success(.suggested(page: Page(start: 0, count: 75)))
        )

    }
}
