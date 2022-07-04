//
//  Etherscan.swift
//  Core
//
//  Created by LL on 6/24/22.
//

import Foundation

public struct EtherscanResponse: Codable {
    let status: String
    let message: String
    let result: String
}

enum Etherscan {
    struct GetABI: DataRequest {
        let url: String = "https://api.etherscan.io/api"
        let address: String

        public init(_ address: String) {
            self.address = address
        }

        var queryItems: [String : String] {
            [
                "module": "contract",
                "action": "getabi",
                "address": address,
                "startblock": "0",
                "endblock": "99999999",
                "sort": "asc",
                "apikey": "UTBK9KWQKE8DVPM8EBCCWW6PZ48UNXNQ3F"
            ]
        }
        typealias Response = [ABIItems]

        func decode(_ data: Data) throws -> [ABIItems] {
            let decoder = JSONDecoder()
            let response = try decoder.decode(EtherscanResponse.self, from: data)
            guard let responseData = response.result.data(using: .utf8) else {
                return []
            }
            return try decoder.decode([ABIItems].self, from: responseData)
        }
    }
}
