//
//  File.swift
//  
//
//  Created by Johan Nyman on 2023-01-01.
//

import Foundation


//public struct SigmetRequestOptions: OptionSet {
//
//    public let rawValue: UInt
//
//    public init(rawValue: UInt) {
//        self.rawValue = rawValue
//    }
//
//    /// All current international Sigmets
//    public static let international = SigmetRequestOptions(rawValue: 1 << 0)
//    /// All current US continental Sigmets
//    public static let usContinental  = SigmetRequestOptions(rawValue: 1 << 1)
//    /// Both international and US continental Sigmets
//    public static let both: SigmetRequestOptions = [.international, .usContinental]
//}


public class SigmetRequest: NSObject, AWCRequest {
    
    public var servicePath: String
    
    public var queryParams: [URLQueryItem] = [] //Not required for sigmets
    
    public typealias Response = [Sigmet]
    
    public init(type: SigmetType = .international) {
        
        /*
         * See https://www.aviationweather.gov/help/webservice?page=sigmetjson
         * and https://www.aviationweather.gov/help/webservice?page=isigmetjson
         * for details of possible parameters.
         */
        
        servicePath = "/cgi-bin/json/IsigmetJSON.php"
        
        if type == .usOnly {
            servicePath = "/cgi-bin/json/SigmetJSON.php"
        }
        
        //bbox=minlon,minlat,maxlon,maxlat - This is the bounding box for area of interest. This limits the stations output in GeoJSON to those within that lat/lon range. The default is -130,20,-60,60.
        //Unfortunately, it does not seem to limit the number of sigmets to this area...
        //Otherwise this should be an input argument, set to [-180, -90, 180, 90] per default.
        /*
         self.queryParams = [
            URLQueryItem(name: "bbox", value: "-30,0,0,80")
        ]
        */
        
    }
    
    public func decode(with data: Data) throws -> [Sigmet] {
        // parse data from AWS and create an array of Sigmet structs
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try jsonDecoder.decode(SigmetResponse.self, from: data)
            var sigmets = response.features
            //First one in international sigmets is just response data, should not be included in response
            //print(String(decoding: data, as: UTF8.self))
            if sigmets.last?.type == .international {
                sigmets.removeFirst()
            }
            // sort sigmets by issue time, latest issue is first in the array
            let sortedSigmets: [Sigmet] = sigmets.sorted {
                $0.properties.validTimeFrom ?? Date.distantPast > $1.properties.validTimeFrom ?? Date.distantPast
            }
            
            return sortedSigmets
            
        } catch {
            dump(error)
            throw AvWeatherError.parsing(message: error.localizedDescription)
        }
        
    }
}

// MARK: - SigmetResponse
struct SigmetResponse: Codable {
    let type: String
    let features: [Sigmet]
}
