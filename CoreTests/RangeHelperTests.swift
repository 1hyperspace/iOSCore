//
//  RepositoryTests.swift
//  CoreTests
//
//  Created by 1Hyper Space on 4/12/21.
//

import XCTest
@testable import Core

class RangeHelperTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testNegativeRanges() {
        XCTAssertEqual(RangeHelper().calculateRange(index: 0, currentRange: -10..<10),.failure(.negativeRange))
        XCTAssertEqual(RangeHelper().calculateRange(index: -1, currentRange: 0..<2),.failure(.negativeIndex))
    }

    func testWithinRanges() {
        XCTAssertEqual(RangeHelper().calculateRange(index: 500, currentRange: 250..<750), .success(.noChangeNeeded))
        XCTAssertEqual(RangeHelper().calculateRange(index: 1, currentRange: 0..<2), .success(.suggested(range: 0..<Constants.pageSize)))
        XCTAssertEqual(RangeHelper().calculateRange(index: 26, currentRange: 0..<60), .success(.noChangeNeeded))
        XCTAssertEqual(RangeHelper().calculateRange(index: 70, currentRange: 0..<80), .success(.suggested(range: 70-Constants.pageSize..<70+Constants.pageSize)))
    }
}
