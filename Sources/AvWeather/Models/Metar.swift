//
//  Metar.swift
//  AvWeather
//
//  Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


/// A model for METAR data returned from ADDS.
///
/// - SeeAlso:
/// https://aviationweather.gov/dataserver/fields?datatype=metar
public struct Metar: Codable {

    public enum MetarType: String, Codable {
        case metar = "METAR"
        case speci = "SPECI"
    }

    public enum QualityControlFlags: String, Codable {
        case corrected = "Corrected"
        case auto = "Fully Automated"
        case autoStation = "Indicates that the automated station type is one of the following: A01|A01A|A02|A02A|AOA|AWOS"
        case maintenanceIndicator = "Maintenance check indicator - maintenance is needed"
        case noSignal = "No signal"
        case lightningSensorOff = "The lightning detection sensor is not operating. Thunderstorm information is not available."
        case freezingRainSensorOff = "The freezing rain sensor is not operating"
        case presentWeatherOff = "The present weather sensor is not operating"
    }

    public enum FlightCategory: String, Codable {
        case vfr = "VFR"
        case mvfr = "MVFR"
        case ifr = "IFR"
        case lifr = "LIFR"
    }

    /// Structure to hold sky condition info.  If `skyCover` is "CLR" then `base` is 0.
    public struct SkyCondition: Codable, Identifiable {
        /// All possible values for sky cover.
        public enum SkyCoverConditions: String, Codable {
            case skc = "SKC"
            case clr = "CLR"
            case cavok = "CAVOK"
            case few = "FEW"
            case sct = "SCT"
            case bkn = "BKN"
            case ovc = "OVC"
            case ovx = "OVX"
        }

        /// Unique ID for this object.
        public let id: UUID
        /// Reported sky cover (i.e. CLR, FEW, SCT, OVC, etc.).
        public let skyCover: SkyCoverConditions
        /// Sky cover base height in AGL.
        public let base: Int

        public init(skyCover: SkyCoverConditions, base: Int) {
            self.id = UUID()
            self.skyCover = skyCover
            self.base = base
        }
    }

    // MARK: Properties

    /// The raw METAR.
    public var rawText: String
    /// The station identifier.  Always a four character alphanumeric (A-Z, 0-9).
    public var stationId: String
    /// Time this METAR was observed.
    public var observationTime: Date
    /// The latitude of the station that reported this METAR. (decimal degrees)
    public var latitude: Double
    /// The logitude of the station that reported this METAR. (decimal degrees)
    public var longitude: Double
    /// Air temperature (C).
    public var temp: Double
    /// Dewpoint temperature (C).
    public var dewpoint: Double
    /// Direction from which the wind is blowing.
    /// A value of `0` indicates the wind direction is variable. (degrees)
    public var windDirection: Int
    /// Wind Speed.
    /// A value of `0` combined with a wind direction of `0` is calm winds. (knots)
    public var windSpeed: Int
    /// Wind gust. (knots)
    public var windGust: Int
    /// Horizontal visibility. (statute miles)
    public var visibility: Double
    /// Altimeter setting. (inches of Hg)
    public var altimeter: Double
    /// Sea level pressure. (millibars)
    public var seaLevelPressure: Double
    /// Information about the METAR station providing the data.
    public var qualityControlFlags: [QualityControlFlags]
    /// Weather string for weather description icon lookup.
    // TODO: figure out how to implement a lookup for WX icons.
    //public var wxString: [String]
    /// Up to four levels of sky cover and bases.
    /// `OVX` is present when vertical visibility is reported.
    public var skyCondition: [SkyCondition]
    /// Flight category of this METAR.
    public var flightCategory: FlightCategory
    /// Pressure change in the past 3 hours. (millibars)
    public var threeHourPressureTendency: Double
    /// Maximum air temperature from the past 6 hours (C).
    public var maxTempPastSixHours: Double
    /// Minimum air temperature from the past 6 hours (C).
    public var minTempPastSixHours: Double
    /// Maximum air temperature from the past 24 hours (C).
    public var maxTempPastTwentyFourHours: Double
    /// Minimum air temperature from the past 24 hours (C).
    public var minTempPastTwentyFourHours: Double
    /// Liquid precipitation since the last regular METAR (inches).
    public var precipSinceLastMetar: Double
    /// Liquid precipitation from the past 3 hours.  `0.0005` is trace precipitation. (inches)
    public var precipPastThreeHours: Double
    /// Liquid precipitation from the past 6 hours.  `0.0005` is trace precipitation. (inches)
    public var precipPastSixHours: Double
    /// Liquid precipitation from the past 24 hours.  `0.0005` is trace precipitation. (inches)
    public var precipPastTwentyFourHours: Double
    /// Snow depth on the ground. (inches)
    public var snowDepth: Double
    /// Vertical visibility. (feet)
    public var verticalVisibility: Int
    /// The metar type (METAR or SPECI).
    public var metarType: MetarType
    /// The elevation of the station that reported this METAR. (meters)
    public var stationElevation: Double

    public init() {
        self.rawText = ""
        self.stationId = ""
        self.observationTime = Date.distantPast
        self.latitude = 0.0
        self.longitude = 0.0
        self.temp = 0.0
        self.dewpoint = 0.0
        self.windDirection = 0
        self.windSpeed = 0
        self.windGust = 0
        self.visibility = 0.0
        self.altimeter = 0.0
        self.seaLevelPressure = 0.0
        self.qualityControlFlags = []
        self.skyCondition = []
        self.flightCategory = .vfr
        self.threeHourPressureTendency = 0.0
        self.maxTempPastSixHours = 0.0
        self.minTempPastSixHours = 0.0
        self.maxTempPastTwentyFourHours = 0.0
        self.minTempPastTwentyFourHours = 0.0
        self.precipSinceLastMetar = 0.0
        self.precipPastThreeHours = 0.0
        self.precipPastSixHours = 0.0
        self.precipPastTwentyFourHours = 0.0
        self.snowDepth = 0.0
        self.verticalVisibility = 0
        self.metarType = .metar
        self.stationElevation = 0.0
    }

}
