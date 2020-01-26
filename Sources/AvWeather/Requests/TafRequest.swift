//
//  TafRequest.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


public class TafRequest: NSObject, ADDSRequest {

    public typealias Response = [Taf]

    public let stationString: String
    public var hoursBeforeNow: Int
    public let queryParams: [URLQueryItem]

    private enum parsingState {
        case taf
        case none
    }
    private var currentState: parsingState = .none
    private var currentItem: Taf = Taf()
    private var buffer: String = ""
    private var parsingErrorMessage: String = ""
    private var tafs: [Taf] = []

    public init(forStation stationString: String, hoursBeforeNow: Int = 2) {

        self.stationString = stationString
        self.hoursBeforeNow = hoursBeforeNow

        self.queryParams = [
            URLQueryItem(name: "dataSource", value: "tafs"),
            URLQueryItem(name: "hoursBeforeNow", value: String(hoursBeforeNow)),
            URLQueryItem(name: "stationString", value: self.stationString),
        ]
    }

    public func decode(with: Data) throws -> [Taf] {
        return [Taf()]
    }
    
}
