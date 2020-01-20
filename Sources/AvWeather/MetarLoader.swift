//
// MetarLoader.swift
// AvWeather
//
import Foundation

public enum skyCoverConditions: String {
    case skc = "SKC"
    case clr = "CLR"
    case cavok = "CAVOK"
    case few = "FEW"
    case sct = "SCT"
    case bkn = "BKN"
    case ovc = "OVC"
    case ovx = "OVX"
}

/// Structure to hold sky condition info.  `skyCover` is a standard sky cover value (i.e. FEW, OVC).
/// `base` is the cloud base height in AGL.  If `skyCover` is "CLR" then `base` is 0.
public struct SkyCondition {
    /// Reported sky cover (i.e. CLR, FEW, SCT, OVC, etc.).
    public let skyCover: skyCoverConditions
    /// Sky cover base height in AGL.
    public let base: Int
}

/// Structure to hold Metar data.
public struct Metar {
    public var rawText: String = ""
    public var stationId: String = ""
    public var observationTime: Date? = nil
    public var latitude: Float = Float.nan
    public var longitude: Float = Float.nan
    public var tempC: Float = Float.nan
    public var dewpointC: Float = Float.nan
    public var windDirDegrees: Int = Int.max
    public var windSpeed: Int = Int.max
    public var windGust: Int = Int.max
    public var visibility: Float = Float.nan
    public var altimeter: Float = Float.nan
    public var seaLevelPressure: Float = Float.nan
    public var skyCondition: [SkyCondition] = []
    public var flightCategory: String = ""
    public var threeHourPressureTendency: Float = Float.nan
}

public struct MetarLoaderError: Error {
    public enum ErrorKind {
        case invalidIcaoId
        case serverError
        case parseError
    }

    public let message: String
    public let kind: ErrorKind
}

public protocol MetarLoaderDelegate {
    func dataLoaded(_ metarLoader: MetarLoader, error: Error?)
}

public class MetarLoader : NSObject {

    /// Station ICAO ID for this MetarLoader.
    public let id: String
    /// Set to array of `Metar` if data is loaded successfully.
    public var metars: [Metar] = []
    /// Flag to indicate if metars are loaded.
    public var isDataLoaded: Bool = false

    /// Dependency injection for URLSession
    private let session: URLSession

    private var receivedData: Data?

    // Variables to track XML parsing
    private enum parsingState: String {
        case metar = "metar"
        case none = "none"
    }
    private var currentState: parsingState = .none
    private var currentItem: Metar?
    private var buffer: String = ""
    private var parsingErrorMessage: String = ""
    private var parsingErrorType: MetarLoaderError.ErrorKind? = nil

    public var delegate: MetarLoaderDelegate?

    public init(forIcaoId id: String, session: URLSession = .shared) {
        self.id = id
        self.session = session

        super.init()
    }

    public func getData() {
        guard let url = URL(string: "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=\(id)&hoursBeforeNow=2") else {
            print("Invalid URL.")
            return
        }

        // get XML data from aviation weather
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                fatalError("Can't get reference to self in URLSession callback.")
            }

            if error != nil,
                let error = error {
                self.handleSessionError(error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    let error = MetarLoaderError(message: "Server error trying to load METAR data.", kind: .serverError)
                self.handleSessionError(error)
                return
            }

            if let mimeType = httpResponse.mimeType, mimeType == "text/xml",
               let data = data {
                let xmlParser = XMLParser.init(data: data)
                xmlParser.delegate = self
                if !xmlParser.parse() {
                    var message = ""
                    var type: MetarLoaderError.ErrorKind = .parseError
                    if self.parsingErrorMessage != "" {
                        message = self.parsingErrorMessage
                        type = .invalidIcaoId
                    } else {
                        message = xmlParser.parserError?.localizedDescription ?? "Failed to parse METAR XML."
                    }
                    let error = MetarLoaderError(message: message, kind: type)
                    self.handleSessionError(error)
                    return
                }

                self.isDataLoaded = true
                self.delegate?.dataLoaded(self, error: nil)
                return
            } else {
                let error = MetarLoaderError(message: "Received bad data from server.", kind: .serverError)
                self.handleSessionError(error)
                return
            }
        }.resume()
    }

    private func handleSessionError(_ error: Error) {
        self.delegate?.dataLoaded(self, error: error)
    }

}

extension MetarLoader: XMLParserDelegate {

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "data" {
            guard let strCount = attributeDict["num_results"],
                let count = Int(strCount) else {
                self.parsingErrorMessage = "Failed to parse METAR XML."
                return
            }

            if count == 0 {
                self.parsingErrorMessage = "Invalid ICAO ID."
                self.parsingErrorType = .invalidIcaoId
                parser.abortParsing()
            }
        }

        if elementName == "METAR" {
            currentState = .metar
            currentItem = Metar()
            #if DEBUG
            print("====== START METAR ======")
            #endif
            return
        }

        if currentState == .metar && elementName == "sky_condition" {
            if let skyCover = attributeDict["sky_cover"] {
                if skyCover == "CLR" {
                    currentItem!.skyCondition.append(SkyCondition(skyCover: .clr, base: 0))
                } else if let baseStr = attributeDict["cloud_base_ft_agl"],
                          let base = Int(baseStr) {
                    currentItem!.skyCondition.append(SkyCondition(skyCover: skyCoverConditions(rawValue: skyCover) ?? .skc, base: base))
                }
            }
            return
        }

        if currentState == .metar {
            buffer = ""
            return
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "METAR" {
            #if DEBUG
            print(currentItem!)
            print("====== END METAR ======\n")
            #endif
            metars.append(currentItem!)
            currentState = .none
            return
        }

        if currentState == .metar {
            switch elementName {
            case "raw_text":
                currentItem!.rawText = buffer

            case "station_id":
                currentItem!.stationId = buffer

            case "observation_time":
                let formatter = ISO8601DateFormatter()
                let date = formatter.date(from: buffer)
                currentItem!.observationTime = date

            case "latitude":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.latitude = value

            case "longitude":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.longitude = value

            case "temp_c":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.tempC = value

            case "dewpoint_c":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.dewpointC = value

            case "wind_dir_degrees":
                guard let value = Int(buffer) else {
                    return
                }
                currentItem!.windDirDegrees = value

            case "wind_speed_kt":
                guard let value = Int(buffer) else {
                    return
                }
                currentItem!.windSpeed = value

            case "wind_gust_kt":
                guard let value = Int(buffer) else {
                    return
                }
                currentItem!.windGust = value

            case "visibility_statute_mi":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.visibility = value

            case "altim_in_hg":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.altimeter = value

            case "sea_level_pressure_mb":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.seaLevelPressure = value

            case "three_hr_pressure_tendency_mb":
                guard let value = Float(buffer) else {
                    return
                }
                currentItem!.threeHourPressureTendency = value

            case "flight_category":
                currentItem!.flightCategory = buffer

            default:
                return
            }
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }
}
