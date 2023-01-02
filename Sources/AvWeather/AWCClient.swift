//
//  ADDSClient.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


public typealias AWCClientCallback<T> = (Result<T, Error>) -> Void

// For backwards compatibility
public typealias ADDSClient = AWCClient

public class AWCClient {
    
    private let awcHostUrlString = "https://aviationweather.gov"
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func send<T: AWCRequest>(_ request: T) async throws -> T.Response {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<T.Response, Error>) in
            
            send(request, completion: { response in
                switch response {
                case .success(let objects):
                    continuation.resume(returning: objects)
                case .failure(let error):
                    // request failed
                    continuation.resume(throwing: error)
                }
            })
        })
    }
    
    public func send<T: AWCRequest>(_ request: T,
                                     completion: @escaping AWCClientCallback<T.Response>) {
        let task = session.dataTask(with: getUrl(for: request)) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AvWeatherError.generic(message: "Can't get HTTP response info.")))
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(AvWeatherError.server(message: "Got status code \(httpResponse.statusCode) from server.")))
                return
            }
            
            if ((T.self is TAFRequest.Type || T.self is MetarRequest.Type) && httpResponse.mimeType != "text/xml") ||
                (T.self is SigmetRequest.Type && httpResponse.mimeType != "application/json") {
                completion(.failure(AvWeatherError.server(message: "Server sent data with wrong mime type.")))
                return
            }
            
            if let data = data {
                do {
                    let awcResponse = try request.decode(with: data)
                    completion(.success(awcResponse))
                } catch {
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /// Creates a URL for a request to the AWC data server.
    private func getUrl<T: AWCRequest>(for request: T) -> URL {
        guard let baseURL = URL(string: (awcHostUrlString + request.servicePath)) else {
            fatalError("Can't create URL to contact AWC server.")
        }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        
        //Only valid for Metar and TAF, but ignored by server for Sigmets anyway
        var queryItems = [
            URLQueryItem(name: "requestType", value: "retrieve"),
            URLQueryItem(name: "format", value: "xml"),
        ]
        queryItems += request.queryParams
        
        components.queryItems = queryItems
        return components.url!
    }
    
}

public extension AWCClient {
    
    static func messageIn(_ error: Error) -> String {
        guard let error = error as? AvWeatherError else {
            return "No AvWeatherError: \(error.localizedDescription)"
        }
        switch error {
        case .parsing(message: let msg):
            return msg
        case .server(message: let msg):
            return msg
        case .generic(message: let msg):
            return msg
        }
    }
}
