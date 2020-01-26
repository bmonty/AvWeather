//
//  ADDSRequest.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


public protocol ADDSRequest {

    associatedtype Response: Decodable

    var queryParams: [URLQueryItem] {get}

    func decode(with: Data) throws -> Response

}
