//
//  FileManager.swift
//  Core
//
//  Created by Lucas Lain on 4/26/21.
//

import Foundation

extension FileManager {
    static func getDocumentsDirectory() -> URL {
        let paths = self.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
