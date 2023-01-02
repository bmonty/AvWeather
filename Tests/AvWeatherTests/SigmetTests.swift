//
//  SigmetTests.swift
//  
//
//  Created by Johan Nyman on 2023-01-01.
//

import XCTest
@testable import AvWeather

class SigmetTests: XCTestCase {

    func testInternationalSigmetRequest() {
        let url = "https://aviationweather.gov/cgi-bin/json/IsigmetJSON.php"

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/ISigmets.json")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolSigmetMock.testURLs = [url: data]
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolSigmetMock.self]

            let session = URLSession(configuration: config)

            let client = AWCClient(session: session)
            let request = SigmetRequest(type: .international)

            let expect = expectation(description: "Got SigmetRequestData")
            var testSigmets: [Sigmet] = []

            client.send(request) { response in
                switch response {
                case .success(let sigmets):
                    testSigmets = sigmets
                    expect.fulfill()

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }

            waitForExpectations(timeout: 2) { error in
                if let error = error {
                    XCTFail("SigmetRequest waiting failed: \(error)")
                    return
                }

                // check data
                XCTAssert(testSigmets.count == 74, "Wrong number of Sigmets")
                
                let sigmet = testSigmets.first(where: { $0.id == "1274007"} )! //First in json file, not in sorted sigmets.
                
                XCTAssert(sigmet.type == .international)
                XCTAssert(sigmet.text == "WVPR31 SPJC 280900\nSPIM SIGMET 2 VALID 280930/281530 SPJC-\nSPIM LIMA FIR VA ERUPTION MT SABANCAYA PSN S1547 W07150\nVA CLD OBS AT 0820Z VA NOT IDENTIFIABLE FM STLT DATA=")
                
                XCTAssert(sigmet.properties.icaoID == "SPJC")
                XCTAssert(sigmet.properties.firID == "SPIM")
                XCTAssert(sigmet.properties.firName == "SPIM LIMA")
                XCTAssert(sigmet.properties.seriesID == "2")
                XCTAssert(sigmet.properties.hazard == .va)
                let formatter = ISO8601DateFormatter()
                var date = formatter.date(from: "2022-12-28T09:30:00Z")
                XCTAssert(sigmet.properties.validTimeFrom == date)
                date = formatter.date(from: "2022-12-28T15:30:00Z")
                XCTAssert(sigmet.properties.validTimeTo == date)
                XCTAssert(sigmet.properties.qualifier == "SABANCAYA") //This is not consistent with AWC documentation of qualifier...
                XCTAssert(sigmet.properties.geometryType == .area)
                XCTAssert(sigmet.properties.coords == "-15.78,-71.00,-15.64,-71.01,-15.50,-71.05,-15.37,-71.11,-15.25,-71.19,-15.14,-71.30,-15.06,-71.42,-15.00,-71.55,-14.96,-71.69,-14.95,-71.83,-14.96,-71.98,-15.00,-72.12,-15.06,-72.25,-15.14,-72.37,-15.25,-72.47,-15.37,-72.55,-15.50,-72.62,-15.64,-72.65,-15.78,-72.67,-15.93,-72.65,-16.07,-72.62,-16.20,-72.55,-16.32,-72.47,-16.42,-72.37,-16.50,-72.25,-16.57,-72.12,-16.60,-71.98,-16.62,-71.83,-16.60,-71.69,-16.57,-71.55,-16.50,-71.42,-16.42,-71.30,-16.32,-71.19,-16.20,-71.11,-16.07,-71.05,-15.93,-71.01,-15.78,-71.00")
                XCTAssert(sigmet.properties.rawSigmet == sigmet.text)
                XCTAssert(sigmet.properties.rawAirSigmet == nil)
                XCTAssert(sigmet.geometry?.type == .polygon)
                XCTAssert(sigmet.geometry?.coordinates[0].count == 37)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }
    
    func testUSSigmetRequest() {
        let url = "https://aviationweather.gov/cgi-bin/json/SigmetJSON.php"

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/Sigmets.json")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolSigmetMock.testURLs = [url: data]
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolSigmetMock.self]

            let session = URLSession(configuration: config)

            let client = AWCClient(session: session)
            let request = SigmetRequest(type: .usOnly)

            let expect = expectation(description: "Got SigmetRequestData")
            var testSigmets: [Sigmet] = []

            client.send(request) { response in
                switch response {
                case .success(let sigmets):
                    testSigmets = sigmets
                    expect.fulfill()

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }

            waitForExpectations(timeout: 2) { error in
                if let error = error {
                    XCTFail("SigmetRequest waiting failed: \(error)")
                    return
                }

                // check data
                XCTAssert(testSigmets.count == 2, "Wrong number of Sigmets")
                
                let sigmet = testSigmets.first(where: { $0.id == "932777"} )! //First in json file, not in sorted sigmets.
                
                XCTAssert(sigmet.type == .usOnly)
                XCTAssert(sigmet.text == "WSUS05 KKCI 281446 \nSLCO WS 281446 \nSIGMET OSCAR 6 VALID UNTIL 281846 \nSIGMET  \nCO NM \nFROM 50W ALS TO 20ESE TBE TO 30N INK TO ELP TO 50W ALS \nOCNL SEV TURB BLW FL200. DUE TO STG LOW LVL WNDS AND MTN WV ACT. \nCONDS CONTG BYD 1846Z.")
                
                XCTAssert(sigmet.properties.icaoID == "KSLC")
                XCTAssert(sigmet.properties.alphaChar == "O")
                XCTAssert(sigmet.properties.hazard == .turb)
                let formatter = ISO8601DateFormatter()
                var date = formatter.date(from: "2022-12-28T14:46:00Z")
                XCTAssert(sigmet.properties.validTimeFrom == date)
                date = formatter.date(from: "2022-12-28T18:46:00Z")
                XCTAssert(sigmet.properties.validTimeTo == date)
                XCTAssert(sigmet.properties.severityValue == 4)
                XCTAssert(sigmet.properties.altitudeLow1 == 0)
                XCTAssert(sigmet.properties.altitudeHi2 == 20000)
                XCTAssert(sigmet.properties.rawSigmet == nil)
                XCTAssert(sigmet.properties.rawAirSigmet == sigmet.text)
                XCTAssert(sigmet.geometry?.type == .polygon)
                XCTAssert(sigmet.geometry?.coordinates[0].count == 5)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }
    
    func testAsyncSigmet() async throws {
        
        let client = AWCClient()
        
        //There must always be at least some sigmets around the world, right?
        let request = SigmetRequest(type: .international)

        do {
            let sigmets = try await client.send(request)
            XCTAssert(sigmets.count > 10, "Too few international sigmets")
        } catch {
            XCTFail("Error thrown getting sigmets: \(AWCClient.messageIn(error))")
        }
        
        // And at least one American?
        let usRequest = SigmetRequest(type: .usOnly)

        do {
            let sigmets = try await client.send(usRequest)
            XCTAssert(sigmets.count >= 1, "No US sigmet")
        } catch {
            XCTFail("Error thrown getting sigmets: \(AWCClient.messageIn(error))")
        }

    }
}
