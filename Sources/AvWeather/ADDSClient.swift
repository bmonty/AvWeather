//
//  ADDSClient.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


public typealias ADDSClientCallback<T> = (Result<T, Error>) -> Void

public class ADDSClient {

    private let addsUrlString = "https://aviationweather.gov/adds/dataserver_current/httpparam"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send<T: ADDSRequest>(_ request: T,
                                     completion: @escaping ADDSClientCallback<T.Response>) {
        let task = session.dataTask(with: getUrl(for: request)) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AvWeatherError.generic(message: "Can't get HTTP response info.")))
                return
            }

            if !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(AvWeatherError.server(message: "Got status code \(httpResponse.statusCode) from server.")))
                return
            }

            if httpResponse.mimeType != "text/xml" {
                completion(.failure(AvWeatherError.server(message: "Server sent data with wrong mime type.")))
                return
            }

            if let data = data {
                do {
                    let addsResponse = try request.decode(with: data)
                    completion(.success(addsResponse))
                } catch {
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    /// Creates a URL for a request to the ADDS data server.
    public func getUrl<T: ADDSRequest>(for request: T) -> URL {
        guard let baseURL = URL(string: addsUrlString) else {
            fatalError("Can't create URL to contact ADDS server.")
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!

        var queryItems = [
            URLQueryItem(name: "requestType", value: "retrieve"),
            URLQueryItem(name: "format", value: "xml"),
        ]
        queryItems += request.queryParams

        components.queryItems = queryItems
        return components.url!
    }

}
