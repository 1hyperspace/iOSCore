//
//  ABIItems.swift
//  Core
//
//  Created by LL on 6/24/22.
//

import Foundation


struct Movie: Storable, Equatable {

    let title: String
    let year: Int
    let cast: [String]
    let genres: [String]
    var id: String {
        title + "\(year)" + "\(genres.joined())" + "\(cast.joined())" // does a SHA
    }

    enum IndexedFields: IndexableKeys {
        case title, year
    }
}
