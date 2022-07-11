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

        guard (firstItem != 0 || lastItem != Constants.pageSize) || (index > Constants.pageSize / 2) else {
            return .success(.noChangeNeeded)
        }

        let leftSide = firstItem + (Constants.pageSize / 2)
        let rightSide = lastItem - (Constants.pageSize / 2)

        guard leftSide < rightSide, (leftSide..<rightSide).contains(index) else {
            let step = index - (index % (Constants.pageSize/2))
            let suggestedRange = max(0,index-Constants.pageSize)..<max(0,index-Constants.pageSize) + step + Constants.pageSize
            return .success(.suggested(page: Page(start: suggestedRange.lowerBound,
                                                  count: suggestedRange.lowerBound.distance(to: suggestedRange.upperBound))))
        }

        return .success(.noChangeNeeded)
    }
}
