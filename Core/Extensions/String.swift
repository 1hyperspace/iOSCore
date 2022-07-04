//
//  String.swift
//  Core
//
//  Created by Lucas Lain on 4/26/21.
//

import Foundation
import CommonCrypto

extension String {
    func toSHA() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    func hashed() -> Int64? {
        guard let integer = UInt64(self.toSHA().prefix(16), radix: 16) else {
            fatalError("Hashing failed: \(self.toSHA().prefix(16))")
        }
        return Int64(bitPattern: integer)
    }
}
