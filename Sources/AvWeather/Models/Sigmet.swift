//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-12-28.
//

import Foundation

public enum SigmetType {
    case international, usOnly
}

/// A model for SIGMET data returned from AWS.
///
/// - SeeAlso:
/// https://www.aviationweather.gov/help/webservice?page=isigmetjson
///
public struct Sigmet: Codable {
    
    public let properties: SigmetProperties
    public let id: String?
    public let geometry: SigmetGeometry?
    
    //Shortcut to text:
    public var text: String {
        properties.rawSigmet ?? properties.rawAirSigmet ?? ""
    }
    
    //Type, to know which properties we can expect
    public var type: SigmetType {
        properties.rawSigmet != nil ? .international : .usOnly
    }
    
    // MARK: - Properties
    public struct SigmetProperties: Codable {
        
        /* International Sigmets */
        
        /// ICAO ID that entered the SIGMET
        public let icaoID: String?
        /// Flight Information Region Identifier
        public let firID: String?
        /// Long name for the FIR
        public let firName: String?
        /// The identifier for the series
        public let seriesID: String?
        /// hazard - TS, TSGR (thunderstorms with hail),
        /// TURB, LLWS (low level wind shear), MTW (mountain wave),
        /// ICING, TC (tropical cyclone), SS (sand storm), DS (dust storm),
        /// VA (volcanic ash), RDOACT CLD (radioactive cloud)
        public let hazard: Hazard?
        /// ISO 8601 formatted date and time when SIGMET is first valid
        public let validTimeFrom: Date?
        /// ISO 8601 formatted date and time when SIGMET ends
        public let validTimeTo: Date?
        /// hazard qualifier such as ISOL (isolated), SEV (severe), EMBD (embedded), etc
        ///  (May sometimes contain other strings)
        public let qualifier: String?
        ///Geometry of region (UNK if unable to decode from SIGMET).
        public let geometryType: GeoType?
        /// Coordinates for the geometry. This might be enough information to establish a region such as "N OF N3200".
        /// Note: Longitude values will be greater than 180 deg when an International SIGMET crosses the International Date Line.
        /// Subtract 360 deg from this value to get the true longitude value.
        public let coords: String?
        /// Lowest level SIGMET is valid in feet
        public let base: Int?
        /// Highest level SIGMET is valid in feet
        public let top: Int?
        /// Direction of movement of hazard in cardinals (or "-")
        public let dir: String?
        /// Speed of movement of hazard in knots
        public let speed: String?
        /// Change of intensity: NC (no change), WKN (weakening), INTSF (intensifying)
        public let change: Change?
        /// Raw SIGMET text
        public let rawSigmet: String?
        
        
        /* US Sigmets */
        
        /// SIGMET, OUTLOOK
        public let airSigmetType: String?
        public let alphaChar: String?
        /// integer severity value (typically 1 or 2, 0 for outlook)
        public var severityValue: Int? {
            Int(severity ?? "")
        }
        /// Severity as String
        public let severity: String? //Used for encode/decode
        /// Lowest level SIGMET is valid in feet
        public let altitudeLow1: Int?
        /// Secondary lowest level SIGMET is valid in feet
        public let altitudeLow2: Int?
        /// Highest level SIGMET is valid in feet
        public let altitudeHi1: Int?
        /// Secondary highest level SIGMET is valid in feet
        public let altitudeHi2: Int?
        /// Raw SIGMET text
        public let rawAirSigmet: String?
        
        
        public enum CodingKeys: String, CodingKey {
            case icaoID = "icaoId"
            case firID = "firId"
            case firName
            case seriesID = "seriesId"
            case hazard, validTimeFrom, validTimeTo, qualifier
            case geometryType = "geom"
            case coords, rawSigmet, top, dir, speed
            case change = "chng"
            case base
            
            case airSigmetType, alphaChar, severity, altitudeLow1, altitudeLow2, altitudeHi1, altitudeHi2, rawAirSigmet
            
        }
        
        public enum Change: String, Codable {
            case intsf = "INTSF"
            case nc = "NC"
            case wkn = "WKN"
        }
        
        ///If the decoder cannot determine a region, the `geom` parameter will specify `UNK
        ///and the geometry output will be an outline for the FIR.
        public enum GeoType: String, Codable {
            case area = "AREA"
            case line = "LINE"
            case point = "POINT"
            case unknown = "UNK"
        }
        
        /// All possible hazards
        public enum Hazard: String, Codable {
            case ice = "ICE"
            case mtw = "MTW"
            case tc = "TC"
            case ts = "TS"
            case tsgr = "TSGR"
            case ss = "SS"
            case ds = "DS"
            case turb = "TURB"
            case llws = "LLWS"
            case va = "VA"
            case rdoactcld = "RDOACT CLD"
            
            //US Specific
            case conv = "CONVECTIVE"
            case icing = "ICING"
            case ifr = "IFR"
            case mtnobsc = "MTN OBSCN"
            case ash = "ASH"
        }
    }
    // MARK: - Geometry
    public struct SigmetGeometry: Codable {
        
        public let type: SigmetGeometryType
        public let coordinates: [Coordinate]
        
        public enum Coordinate: Codable {
            case point(latlong: Double)
            case line(latlongPair: [Double])
            case polygon(latlongPairs: [[Double]])
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let x = try? container.decode([[Double]].self) {
                    self = .polygon(latlongPairs: x)
                    return
                }
                if let x = try? container.decode([Double].self) {
                    self = .line(latlongPair: x)
                    return
                }
                if let x = try? container.decode(Double.self) {
                    self = .point(latlong: x)
                    return
                }
                throw DecodingError.typeMismatch(Coordinate.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Coordinate"))
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .point(let x):
                    try container.encode(x)
                case .line(let x):
                    try container.encode(x)
                case .polygon(let x):
                    try container.encode(x)
                }
            }
            
            var getCoords: Any {
                switch self {
                case .point(latlong: let value):
                    return value
                case .line(latlongPair: let value):
                    return value
                case .polygon(latlongPairs: let value):
                    return value
                }
            }
        }
        
        
        
        public enum SigmetGeometryType: String, Codable {
            case line = "LineString"
            case point = "Point"
            case polygon = "Polygon"
        }
    }
}
