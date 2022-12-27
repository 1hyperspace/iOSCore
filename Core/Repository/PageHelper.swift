//
//  RangeHelper.swift
//  Core
//
//  Created by 1Hyper Space on 4/12/21.
//

import Foundation

public struct PageHelper {
    public enum PageError: Error, Equatable {
        case negativeIndex
        case negativeRange
    }

    public enum Suggestion: Equatable {
        case suggested(page: Page)
        case noChangeNeeded
    }

    func calculatePage(index: Int, current: Page) -> Result<Suggestion, PageError> {
        guard index >= 0 else {
            return .failure(.negativeIndex)
        }

        let firstItem = current.start
        let lastItem = current.start + current.count

        guard firstItem >= 0 else {
            return .failure(.negativeRange)
        }

        guard (firstItem != 0 || lastItem != Constants.pageSize) || (index > Constants.pageTriggerGap) else {
            return .success(.noChangeNeeded)
        }

        let leftSide = firstItem + (Constants.pageTriggerGap)
        let rightSide = lastItem - (Constants.pageTriggerGap)

        guard leftSide < rightSide, (leftSide..<rightSide).contains(index) else {
            // TODO: This is a little shaky
            let step = max(0, Int((index - Constants.pageTriggerGap) / (Constants.pageSize/2)) * (Constants.pageSize/2))
            let newPage = Page(start: step,
                               count: Constants.pageSize)

            return (current == newPage) ? .success(.noChangeNeeded) : .success(.suggested(page: newPage))
        }

        return .success(.noChangeNeeded)
    }
}
