//
// MetarRequest.swift
// AvWeather
//
// Created by Benjamin Montgomery on 1/25/20.
//

import Foundation


public class MetarRequest: NSObject, ADDSRequest {

    public typealias Response = [Metar]

    public let stationString: String
    public let hoursBeforeNow: Int
    public var queryParams: [URLQueryItem]

    private enum parsingState {
        case metar
        case none
    }
    private var currentState: parsingState = .none
    private var currentItem: Metar = Metar()
    private var buffer: String = ""
    private var parsingErrorMessage: String = ""
    private var metars: [Metar] = []

    public init(forStation stationString: String, hoursBeforeNow: Int = 2, mostRecent: Bool = false) {

        self.stationString = stationString
        self.hoursBeforeNow = hoursBeforeNow

        self.queryParams = [
            URLQueryItem(name: "dataSource", value: "metars"),
            URLQueryItem(name: "hoursBeforeNow", value: String(hoursBeforeNow)),
            URLQueryItem(name: "stationString", value: self.stationString),
        ]

        if mostRecent {
            queryParams.append(URLQueryItem(name: "mostRecent", value: "true"))
        }
    }

    public func decode(with data: Data) throws -> [Metar] {
        let xmlParser = XMLParser.init(data: data)
        xmlParser.delegate = self
        if !xmlParser.parse() {
            throw AvWeatherError.parsing(message: parsingErrorMessage)
        }

        return metars
    }

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "data":
            guard let strCount = attributeDict["num_results"],
                let count = Int(strCount) else {
                    parsingErrorMessage = "Failed to parse METAR XML."
                    parser.abortParsing()
                    return
            }

            // ADDS will return 0 results with an invalid station string
            if count == 0 {
                parsingErrorMessage = "Invalid station string."
                parser.abortParsing()
            }

        case "METAR":
            currentState = .metar
            currentItem = Metar()

        case "sky_condition":
            if currentState == .metar {
                if let skyCover = attributeDict["sky_cover"] {
                    if skyCover == "CLR" {
                        currentItem.skyCondition.append(Metar.SkyCondition(skyCover: .clr, base: 0))
                    } else if let baseStr = attributeDict["cloud_base_ft_agl"],
                        let base = Int(baseStr) {
                        currentItem.skyCondition.append(Metar.SkyCondition(skyCover: Metar.SkyCondition.SkyCoverConditions.init(rawValue: baseStr) ?? .skc, base: base))
                    }
                }
                return
            }

        default:
            // this is a new element under METAR, so clear the data buffer
            if currentState == .metar {
                buffer = ""
                return
            }
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // found end of the METAR section, so save the data
        if elementName == "METAR" {
            metars.append(currentItem)
            currentState = .none
            return
        }

        // found end of an element under METAR, so add the data to currentItem
        if currentState == .metar {
            switch elementName {
            case "raw_text":
                currentItem.rawText = buffer

            case "station_id":
                currentItem.stationId = buffer

            case "observation_time":
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: buffer) {
                    currentItem.observationTime = date
                } else {
                    parsingErrorMessage = "Failed to parse date from METAR XML."
                    parser.abortParsing()
                    return
                }

            case "latitude":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse latitude."
                    parser.abortParsing()
                    return
                }
                currentItem.latitude = value

            case "longitude":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse longitude."
                    parser.abortParsing()
                    return
                }
                currentItem.longitude = value

            case "temp_c":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse temperature."
                    parser.abortParsing()
                    return
                }
                currentItem.temp = value

            case "dewpoint_c":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse dewpoint."
                    parser.abortParsing()
                    return
                }
                currentItem.dewpoint = value

            case "wind_dir_degrees":
                guard let value = Int(buffer) else {
                    parsingErrorMessage = "Failed to parse wind direction."
                    parser.abortParsing()
                    return
                }
                currentItem.windDirection = value

            case "wind_speed_kt":
                guard let value = Int(buffer) else {
                    parsingErrorMessage = "Failed to parse wind speed."
                    parser.abortParsing()
                    return
                }
                currentItem.windSpeed = value

            case "wind_gust_kt":
                guard let value = Int(buffer) else {
                    parsingErrorMessage = "Failed to parse wind gust."
                    parser.abortParsing()
                    return
                }
                currentItem.windGust = value

            case "visibility_statute_mi":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse visbility."
                    parser.abortParsing()
                    return
                }
                currentItem.visibility = value

            case "altim_in_hg":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse altimeter setting."
                    parser.abortParsing()
                    return
                }
                currentItem.altimeter = value

            case "sea_level_pressure_mb":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse sea level pressure."
                    parser.abortParsing()
                    return
                }
                currentItem.seaLevelPressure = value

            case "flight_category":
                guard let flightCategory = Metar.FlightCategory.init(rawValue: buffer) else {
                    parsingErrorMessage = "Failed to parse flight category."
                    parser.abortParsing()
                    return
                }
                currentItem.flightCategory = flightCategory

            case "three_hr_pressure_tendency_mb":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse three hour pressure tendency."
                    parser.abortParsing()
                    return
                }
                currentItem.threeHourPressureTendency = value

            case "maxT_c":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse maximum air temperature from the past 6 hours."
                    parser.abortParsing()
                    return
                }
                currentItem.maxTempPastSixHours = value

            case "minT_c":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse minimum air temperature from the past 6 hours."
                    parser.abortParsing()
                    return
                }
                currentItem.minTempPastSixHours = value

            case "maxT24hr_c":
            guard let value = Double(buffer) else {
                parsingErrorMessage = "Failed to parse maximum air temperature from the past 24 hours."
                parser.abortParsing()
                return
            }
            currentItem.maxTempPastTwentyFourHours = value

            case "minT24hr_c":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse minimum air temperature from the past 24 hours."
                    parser.abortParsing()
                    return
                }
                currentItem.minTempPastTwentyFourHours = value

            case "precip_in":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse precip since last METAR."
                    parser.abortParsing()
                    return
                }
                currentItem.precipSinceLastMetar = value

            case "pcp3hr_in":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse precip from last 3 hours."
                    parser.abortParsing()
                    return
                }
                currentItem.precipPastThreeHours = value

            case "pcp6hr_in":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse precip from last 6 hours."
                    parser.abortParsing()
                    return
                }
                currentItem.precipPastSixHours = value

            case "pcp24hr_in":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse precip from last 24 hours."
                    parser.abortParsing()
                    return
                }
                currentItem.precipPastTwentyFourHours = value

            case "snow_in":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse snow depth."
                    parser.abortParsing()
                    return
                }
                currentItem.snowDepth = value

            case "vert_vis_ft":
                guard let value = Int(buffer) else {
                    parsingErrorMessage = "Failed to parse vertical visibility."
                    parser.abortParsing()
                    return
                }
                currentItem.verticalVisibility = value

            case "metar_type":
                guard let metarType = Metar.MetarType.init(rawValue: buffer) else {
                    parsingErrorMessage = "Failed to parse METAR type."
                    parser.abortParsing()
                    return
                }
                currentItem.metarType = metarType

            case "elevation":
                guard let value = Double(buffer) else {
                    parsingErrorMessage = "Failed to parse station elevation."
                    parser.abortParsing()
                    return
                }
                currentItem.stationElevation = value

            default:
                return
            }
        }
    }

    // get data from an element
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }
}

extension MetarRequest: XMLParserDelegate {



}
