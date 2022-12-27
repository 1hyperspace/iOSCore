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
            PageHelper().calculatePage(index: 300, current: Page(start: 250, count: Constants.pageSize)),
            .success(.noChangeNeeded)
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 1, current: Page(start: 0, count: Constants.pageSize)),
            .success(.noChangeNeeded)
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 26, current: Page(start: 0, count: Constants.pageSize)),
            .success(.noChangeNeeded)
        )

        XCTAssertEqual(
            PageHelper().calculatePage(index: 70, current: Page(start: 0, count: Constants.pageSize)),
            .success(.noChangeNeeded)
        )
    }

    func testCloseToLeft() {
        XCTAssertEqual(
            PageHelper().calculatePage(index: 109, current: Page(start: 100, count: Constants.pageSize)),
            .success(.suggested(page: Page(start: 50, count: Constants.pageSize)))
        )
    }

    func testCloseToRight() {
        XCTAssertEqual(
            PageHelper().calculatePage(index: 149, current: Page(start: 50, count: Constants.pageSize)),
            .success(.suggested(page: Page(start: 100, count: Constants.pageSize)))
        )
    }
}
