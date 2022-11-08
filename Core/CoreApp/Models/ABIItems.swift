//
//  ABIItems.swift
//  Core
//
//  Created by LL on 6/24/22.
//

import Foundation

public struct ABIItems: Storable, Equatable {
    var address: String?
    let type: String
    let name: String?
}

extension ABIItems {
    public static var version: Int = 1
    public var id: String {
        address! + (name ?? "")
    }
}
