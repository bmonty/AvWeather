//
//  AvWeatherError.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


public enum AvWeatherError: Error {
    case parsing(message: String)
    case server(message: String)
    case generic(message: String)
}
