//
// TAFRequest.swift
// AvWeather
//
// Created by Johan Bergsee on 2022-12-07.
//

import Foundation


public class TAFRequest: NSObject, XMLParserDelegate, ADDSRequest {
    
    public typealias Response = [TAF]
    
    public let stationString: [String]
    public let hoursBeforeNow: Int
    public var queryParams: [URLQueryItem]
    
    private enum parsingState {
        case taf
        case forecast
        case none
    }
    private var currentState: parsingState = .none
    private var currentTaf: TAF = TAF()
    private var currentForecast: TAF.Forecast = TAF.Forecast()
    private var buffer: String = ""
    private var parsingErrorMessage: String = ""
    private var tafs: [TAF] = []
    
    public convenience init(forStation stationString: String, hoursBeforeNow: Int = 12, mostRecent: Bool = false) {
        self.init(forStations: [stationString], hoursBeforeNow: hoursBeforeNow, mostRecent: mostRecent)
    }
    
    public init(forStations stationString: [String], hoursBeforeNow: Int = 12, mostRecent: Bool = false) {
        self.stationString = stationString
        self.hoursBeforeNow = hoursBeforeNow
        
        /*
         * See https://www.aviationweather.gov/dataserver/example?datatype=taf
         * for details of possible parameters.
         */
        self.queryParams = [
            URLQueryItem(name: "dataSource", value: "tafs"),
            URLQueryItem(name: "hoursBeforeNow", value: String(hoursBeforeNow)),
            URLQueryItem(name: "stationString", value: self.stationString.joined(separator: ",")),
        ]
        
        if mostRecent {
            queryParams.append(URLQueryItem(name: "mostRecentForEachStation", value: "constraint"))
        }
    }
    
    public func decode(with data: Data) throws -> [TAF] {
        // parse data from ADDS and create an array of TAF structs
        let xmlParser = XMLParser.init(data: data)
        xmlParser.delegate = self
        if !xmlParser.parse() {
            throw AvWeatherError.parsing(message: parsingErrorMessage)
        }
        
        // sort tafs by issue time, latest issue is first in the array
        let sortedTafs = tafs.sorted {
            $0.issueTime > $1.issueTime
        }
        
        return sortedTafs
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
            
        case "data":
            guard let strCount = attributeDict["num_results"],
                  let count = Int(strCount) else {
                      parsingErrorMessage = "Failed to parse TAF XML."
                      parser.abortParsing()
                      return
                  }
            
            // ADDS will return 0 results with an invalid station string
            if count == 0 {
                parsingErrorMessage = "Invalid station string."
                parser.abortParsing()
            }
            
        case "TAF":
            currentState = .taf
            currentTaf = TAF()
            
        case "forecast":
            //Starting a new Forecast within a TAF
            currentState = .forecast
            currentForecast = TAF.Forecast()
            
        case "sky_condition":
            if currentState == .forecast {
                if let skyCover = attributeDict["sky_cover"] {
                    if skyCover == "CLR" {
                        currentForecast.skyCondition.append(TAF.SkyCondition(skyCover: .clr, cloudBaseFtAgl: 0))
                    } else if let baseStr = attributeDict["cloud_base_ft_agl"],
                              let base = Int(baseStr) {
                        var sky = TAF.SkyCondition(skyCover: TAF.SkyCondition.SkyCoverConditions.init(rawValue: skyCover) ?? .skc, cloudBaseFtAgl: base)
                        if let clouds = attributeDict["cloud_type"] {
                            sky.cloudType = TAF.SkyCondition.CloudType(rawValue: clouds)
                        }
                        currentForecast.skyCondition.append(sky)
                    }
                }
                return
            }
            
        case "turbulence_condition":
            print("Please implement parsing of turbulence condition or post an issue on github giving the TAF station, time and attributeDict below:")
            print(attributeDict)
            return
            
        case "icing_condition":
            print("Please implement parsing of icing condition or post an issue on github giving the TAF station, time and attributeDict below:")
            print(attributeDict)
            return
            
        case "temperature":
            print("Please implement parsing of temperatures or post an issue on github giving the TAF station, time and attributeDict below:")
            print(attributeDict)
            return
            
        default:
            // this is a new element, so clear the data buffer
            buffer = ""
            return
        }
        buffer = ""
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        switch elementName {
            
        case "error":
            //Check for errors in XML response
            if !buffer.isEmpty {
                parsingErrorMessage = buffer
                parser.abortParsing()
            }
            return
            
        case "warning":
            //Log any warnings in XML response
            if !buffer.isEmpty {
                // Do not abort...
                print(buffer)
            }
            return
            
        case "TAF" :
            // found end of the TAF section, so save the data
            tafs.append(currentTaf)
            currentState = .none
            return
            
        case "forecast" :
            // found end of the Forecast section, so save the data
            currentTaf.forecast.append(currentForecast)
            currentState = .taf
            return
            
        default:
            
            if currentState == .taf {
                // found end of an element under TAF, so add the data to currentTaf
                switch elementName {
                case "raw_text":
                    currentTaf.rawText = buffer
                    
                case "station_id":
                    currentTaf.stationId = buffer
                    
                case "issue_time":
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: buffer) {
                        currentTaf.issueTime = date
                    } else {
                        parsingErrorMessage = "Failed to parse date from TAF XML."
                        parser.abortParsing()
                        return
                    }
                    
                case "bulletin_time":
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: buffer) {
                        currentTaf.bulletinTime = date
                    } else {
                        parsingErrorMessage = "Failed to parse date from TAF XML."
                        parser.abortParsing()
                        return
                    }
                    
                case "valid_time_from":
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: buffer) {
                        currentTaf.validTimeFrom = date
                    } else {
                        parsingErrorMessage = "Failed to parse date from TAF XML."
                        parser.abortParsing()
                        return
                    }
                    
                case "valid_time_to":
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: buffer) {
                        currentTaf.validTimeTo = date
                    } else {
                        parsingErrorMessage = "Failed to parse date from TAF XML."
                        parser.abortParsing()
                        return
                    }
                    
                case "remarks":
                    currentTaf.remarks = buffer
                    
                case "latitude":
                    guard let value = Double(buffer) else {
                        parsingErrorMessage = "Failed to parse latitude."
                        parser.abortParsing()
                        return
                    }
                    currentTaf.latitude = value
                    
                case "longitude":
                    guard let value = Double(buffer) else {
                        parsingErrorMessage = "Failed to parse longitude."
                        parser.abortParsing()
                        return
                    }
                    currentTaf.longitude = value
                    
                case "elevation_m":
                    guard let value = Double(buffer) else {
                        parsingErrorMessage = "Failed to parse station elevation."
                        parser.abortParsing()
                        return
                    }
                    currentTaf.elevationM = value
                default:
                    return
                }
                
            } else if currentState == .forecast {
                // found end of an element under Forecast, so add the data to currentForecast
                switch elementName {
                    
                case "fcst_time_from":
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: buffer) {
                        currentForecast.fcstTimeFrom = date
                    } else {
                        parsingErrorMessage = "Failed to parse date from Forecast XML."
                        parser.abortParsing()
                        return
                    }
                case "fcst_time_to":
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: buffer) {
                        currentForecast.fcstTimeTo = date
                    } else {
                        parsingErrorMessage = "Failed to parse date from Forecast XML."
                        parser.abortParsing()
                        return
                    }
                    
                case "change_indicator":
                    guard let changeIndicator = TAF.Forecast.ChangeIndicator(rawValue: buffer) else {
                        parsingErrorMessage = "Failed to parse Forecast change indicator."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.changeIndicator = changeIndicator
                    
                case "time_becoming":
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: buffer) {
                        currentForecast.timeBecoming = date
                    } else {
                        parsingErrorMessage = "Failed to parse date from Forecast XML."
                        parser.abortParsing()
                        return
                    }
                    
                case "probability":
                    guard let value = Int(buffer) else {
                        parsingErrorMessage = "Failed to parse probability."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.probability = value
                    
                case "wind_dir_degrees":
                    guard let value = Int(buffer) else {
                        parsingErrorMessage = "Failed to parse wind direction."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.windDirDegrees = value
                    
                case "wind_speed_kt":
                    guard let value = Int(buffer) else {
                        parsingErrorMessage = "Failed to parse wind speed."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.windSpeedKt = value
                    
                case "wind_gust_kt":
                    guard let value = Int(buffer) else {
                        parsingErrorMessage = "Failed to parse wind gust."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.windGustKt = value
                    
                case "wind_shear_dir_degrees":
                    guard let value = Int(buffer) else {
                        parsingErrorMessage = "Failed to parse wind shear direction."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.windShearDirDegrees = value
                    
                case "wind_shear_speed_kt":
                    guard let value = Int(buffer) else {
                        parsingErrorMessage = "Failed to parse wind shear speed."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.windShearSpeedKt = value
                    
                case "wind_shear_hgt_ft_agl":
                    guard let value = Int(buffer) else {
                        parsingErrorMessage = "Failed to parse wind shear height."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.windShearHgtFtAgl = value
                    
                case "visibility_statute_mi":
                    guard let value = Double(buffer) else {
                        parsingErrorMessage = "Failed to parse visbility."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.visibilityStatuteMi = value
                    
                case "altim_in_hg":
                    guard let value = Double(buffer) else {
                        parsingErrorMessage = "Failed to parse altimeter inch Hg."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.altimInHg = value
                    
                case "vert_vis_ft":
                    guard let value = Double(buffer) else {
                        parsingErrorMessage = "Failed to parse vertical visbility."
                        parser.abortParsing()
                        return
                    }
                    currentForecast.vertVisFt = value
                    
                case "wx_string":
                    currentForecast.wxString = buffer
                    
                case "not_decoded":
                    currentForecast.notDecoded = buffer
                    
                default:
                    return
                }
            }
        }
    }
    
    // get data from an element
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }
}
