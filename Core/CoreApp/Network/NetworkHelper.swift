//
//  NetworkHelper.swift
//  Core
//
//  Created by LL on 6/24/22.
//

import Foundation

enum NetworkError: Error {
    case urlError
    case queryItems
    case dataTaskError(Error)
    case noData
    case decodingError(Error)
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol DataRequest {
    associatedtype Response

    var url: String { get }
    var method: HTTPMethod { get }
    var headers: [String : String] { get }
    var queryItems: [String : String] { get }

    func decode(_ data: Data) throws -> Response
}

extension DataRequest where Response: Decodable {
    func decode(_ data: Data) throws -> Response {
        let decoder = JSONDecoder()
        return try decoder.decode(Response.self, from: data)
    }
}

extension DataRequest {
    var method: HTTPMethod {
        .get
    }

    var headers: [String : String] {
        [:]
    }

    var queryItems: [String : String] {
        [:]
    }
}

class NetworkHelper {
    func send<Request: DataRequest>(_ request: Request,
                                    handler: @escaping ((Result<Request.Response, NetworkError>) -> Void)) -> URLSessionDataTask? {

        guard var urlComponent = URLComponents(string: request.url) else {
            handler(.failure(.urlError))
            return nil
        }

        var queryItems: [URLQueryItem] = []

        request.queryItems.forEach {
            let urlQueryItem = URLQueryItem(name: $0.key, value: $0.value)
            urlComponent.queryItems?.append(urlQueryItem)
            queryItems.append(urlQueryItem)
        }

        urlComponent.queryItems = queryItems

        guard let url = urlComponent.url else {
            handler(.failure(.queryItems))
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                handler(.failure(.dataTaskError(error)))
            }

            guard let data = data else {
                handler(.failure(.noData))
                return
            }

            do {
                try handler(.success(request.decode(data)))
            } catch let error as NSError {
                handler(.failure(.decodingError(error)))
            }
        }

        dataTask.resume()
        return dataTask
    }
}
