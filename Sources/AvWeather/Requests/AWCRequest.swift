//
//  ADDSRequest.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation

// For backwards compatibility
public typealias ADDSRequest = AWCRequest

public protocol AWCRequest {

    associatedtype Response: Decodable
    
    var servicePath: String { get }

    var queryParams: [URLQueryItem] { get }

    func decode(with: Data) throws -> Response

}
