//
//  Taf.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


/// A model for TAF data return from ADDS.
///
/// - SeeAlso:
/// https://aviationweather.gov/dataserver/fields?datatype=taf
public struct Taf: Codable {

    /// The raw TAF in text.
    var rawTaf: String = ""

}
