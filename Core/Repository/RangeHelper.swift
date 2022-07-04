//
//  RangeHelper.swift
//  Core
//
//  Created by 1Hyper Space on 4/12/21.
//

import Foundation

public struct RangeHelper {
    public enum RangerError: Error, Equatable {
        case negativeIndex
        case negativeRange
    }

    public enum Suggestion: Equatable {
        case suggested(range: Range<Int>)
        case noChangeNeeded
    }

    func calculateRange(index: Int, currentRange: Range<Int>) -> Result<Suggestion, RangerError> {
        guard let firstItem = currentRange.first, let lastItem = currentRange.last, index >= 0 else {
            return .failure(.negativeIndex)
        }

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
            return .success(.suggested(range: suggestedRange))
        }

        return .success(.noChangeNeeded)
    }
}
