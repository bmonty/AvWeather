//
//  TAF.swift
//  AvWeather
//
//  Created by Johan Bergsee on 2022-12-07.
//

import Foundation

/// A model for TAF data returned from AWC.
///
/// - SeeAlso:
/// https://aviationweather.gov/dataserver/fields?datatype=taf
public struct TAF: Codable {
    
    /// Structure to hold sky condition info.  If `skyCover` is "CLR" then `cloudBaseFtAgl` is 0.
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
        
        /// All possible values for cloud type
        public enum CloudType: String, Codable {
            case cb = "CB"
            case tcu = "TCU"
            case cu = "CU"
        }
        
        /// Unique ID for this object.
        public let id: UUID
        /// Reported sky cover (i.e. CLR, FEW, SCT, OVC, etc.).
        public let skyCover: SkyCoverConditions
        /// Sky cover base height in ft AGL.
        public let cloudBaseFtAgl: Int
        /// Cloud type (i.e CB, TCU, CU
        public var cloudType: CloudType?
        
        public init(skyCover: SkyCoverConditions, cloudBaseFtAgl: Int, cloudType: CloudType? = nil) {
            self.id = UUID()
            self.skyCover = skyCover
            self.cloudBaseFtAgl = cloudBaseFtAgl
            self.cloudType = cloudType
        }
    }
    
    public struct TurbulenceCondition: Codable {
        /// Turbulence intensity values: [0-9]
        /// Please refer to WMO No. 306 Manual on Codes for more details.
        public var turbulenceIntensity: Int
        /// Minimum altitude for turbulence
        public var turbulenceMinAltFtAgl: Int
        /// Maximum altitude for turbulence
        public var turbulenceMaxAltFtAgl: Int
        
        public init(turbulenceIntensity: Int = 0, turbulenceMinAltFtAgl: Int = 0, turbulenceMaxAltFtAgl: Int = 0) {
            self.turbulenceIntensity = turbulenceIntensity
            self.turbulenceMinAltFtAgl = turbulenceMinAltFtAgl
            self.turbulenceMaxAltFtAgl = turbulenceMaxAltFtAgl
        }
    }
    
    public struct IcingCondition: Codable {
        /// Icing intensity values: [0-9]
        /// Please refer to WMO No. 306 Manual on Codes for more details.
        public var icingIntensity: Int
        /// Minimum altitude for icing
        public var icingMinAltFtAgl: Int
        /// Maximum altitude for icing
        public var icingMaxAltFtAgl: Int
        
        public init(icingIntensity: Int = 0, icingMinAltFtAgl: Int = 0, icingMaxAltFtAgl: Int = 0) {
            self.icingIntensity = icingIntensity
            self.icingMinAltFtAgl = icingMinAltFtAgl
            self.icingMaxAltFtAgl = icingMaxAltFtAgl
        }
    }
    
    public struct Temperature: Codable {
        /// Temperature valid time
        public var validTime: Date
        /// Surface temperature (°C)
        public var sfcTempC: Double?
        /// Max temperature (°C)
        public var maxTempC: Double?
        /// Min temperature (°C)
        public var minTempC: Double?
        
        public init(validTime: Date, sfcTempC: Double? = nil, maxTempC: Double? = nil, minTempC: Double? = nil) {
            self.validTime = validTime
            self.sfcTempC = sfcTempC
            self.maxTempC = maxTempC
            self.minTempC = minTempC
        }
    }
    
    // MARK: Properties
    
    /// The raw TAF.
    public var rawText: String
    /// The station identifier.  Always a four character alphanumeric (A-Z, 0-9).
    public var stationId: String
    /// Issue time (date and time the forecast was prepared)
    public var issueTime: Date
    /// Bulletin time (obtained from the WMO Header of the data)
    public var bulletinTime: Date
    /// The start time of when the report is valid
    public var validTimeFrom: Date
    /// The end time for when the report is valid
    public var validTimeTo: Date
    /// Any remarks.
    public var remarks: String?
    /// The latitude of the station that reported this TAF. (decimal degrees)
    public var latitude: Double
    /// The logitude of the station that reported this TAF. (decimal degrees)
    public var longitude: Double
    /// Elevation in meters
    public var elevationM: Double
    /// An array of data for a specific forecast period.
    public var forecast: [Forecast]
    
    // MARK: Forecast groups
    
    public struct Forecast: Codable {
        /// All possible values for change indicator type
        public enum ChangeIndicator: String, Codable {
            case tempo = "TEMPO"
            case becmg = "BECMG"
            case fm = "FM"
            case prob = "PROB"
        }
        
        //The following elements are within a forecast group
        
        /// The start of the forecast time
        public var fcstTimeFrom: Date
        /// The end of the forecast time
        public var fcstTimeTo: Date
        /// Forecast change indicator: TEMPO, BECMG, FM, PROB
        public var changeIndicator: ChangeIndicator?
        /// Time becoming
        public var timeBecoming: Date?
        /// Percent probability
        public var probability: Int?
        /// Wind direction-the direction in degrees from where the wind is blowing
        public var windDirDegrees: Int?
        /// Wind speed
        public var windSpeedKt: Int?
        /// Wind gust
        public var windGustKt: Int?
        /// Wind shear height above ground level
        public var windShearHgtFtAgl: Int?
        /// Wind shear direction
        public var windShearDirDegrees :Int?
        ///  Wind shear speed
        public var windShearSpeedKt: Int?
        /// Visibility (horizontal)
        public var visibilityStatuteMi: Double?
        /// Altimeter in inches of mercury
        public var altimInHg: Double?
        /// Vertical visibility (in ft)
        public var vertVisFt: Double?
        /// Weather
        public var wxString: String?
        /// Indicates what isn't decoded
        public var notDecoded: String?
        
        public var skyCondition: [SkyCondition]
        
        public var turbulenceCondition: [TurbulenceCondition]
        
        public var icingCondition: [IcingCondition]
        /// An array of Temperature data
        public var temperature: [Temperature]
        
        public init() {
            self.fcstTimeFrom = Date.distantPast
            self.fcstTimeTo = Date.distantPast
            self.changeIndicator = nil
            self.timeBecoming = nil
            self.probability = nil
            self.windDirDegrees = nil
            self.windSpeedKt = nil
            self.windGustKt = nil
            self.windShearHgtFtAgl = nil
            self.windShearDirDegrees = nil
            self.windShearSpeedKt = nil
            self.visibilityStatuteMi = nil
            self.altimInHg = nil
            self.vertVisFt = nil
            self.wxString = nil
            self.notDecoded = nil
            self.skyCondition = []
            self.turbulenceCondition = []
            self.icingCondition = []
            self.temperature = []
        }
    }
    
    public init() {
        self.rawText = ""
        self.stationId = ""
        self.issueTime = Date.distantPast
        self.bulletinTime = Date.distantPast
        self.validTimeFrom = Date.distantPast
        self.validTimeTo = Date.distantPast
        self.remarks = nil
        self.latitude = 0.0
        self.longitude = 0.0
        self.elevationM = 0.0
        self.forecast = []
    }
}
