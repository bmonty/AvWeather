//
//  TAFTests.swift
//  
//
//  Created by Johan Nyman on 2022-12-08.
//

import XCTest
@testable import AvWeather

class TAFTests: XCTestCase {

    func testTAFRequest() {
        let url = "https://aviationweather.gov/adds/dataserver_current/httpparam"

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/example_TAFs.xml")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolAvWeatherMock.testURLs = [url: data]
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolAvWeatherMock.self]

            let session = URLSession(configuration: config)

            let client = ADDSClient(session: session)
            let request = TAFRequest(forStation: "PHTO")

            let expect = expectation(description: "Got TAFRequestData")
            var testTAFs: [TAF] = []

            client.send(request) { response in
                switch response {
                case .success(let tafs):
                    testTAFs = tafs
                    expect.fulfill()

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }

            waitForExpectations(timeout: 2) { error in
                if let error = error {
                    XCTFail("TAFRequest waiting failed: \(error)")
                    return
                }

                // check latest TAF has index 0, and data is correct
                let taf = testTAFs[0]
                XCTAssert(taf.rawText == "PHTO 071741Z 0718/0818 23005KT P6SM VCSH SCT025 BKN040 FM072000 11010KT P6SM VCSH SCT025 BKN040 FM080600 25007KT P6SM VCSH SCT025 BKN040")
                XCTAssert(taf.stationId == "PHTO")
                let formatter = ISO8601DateFormatter()
                var date = formatter.date(from: "2022-12-07T17:41:00Z")
                XCTAssert(taf.issueTime == date)
                date = formatter.date(from: "2022-12-07T17:41:00Z")
                XCTAssert(taf.bulletinTime == date)
                date = formatter.date(from: "2022-12-07T18:00:00Z")
                XCTAssert(taf.validTimeFrom == date)
                date = formatter.date(from: "2022-12-08T18:00:00Z")
                XCTAssert(taf.validTimeTo == date)
                XCTAssert(taf.latitude == 19.72)
                XCTAssert(taf.longitude == -155.05)
                XCTAssert(taf.elevationM == 9.0)
                
                //First forecast group
                var forecast = taf.forecast[0]
                date = formatter.date(from: "2022-12-07T18:00:00Z")
                XCTAssert(forecast.fcstTimeFrom == date)
                date = formatter.date(from: "2022-12-07T20:00:00Z")
                XCTAssert(forecast.fcstTimeTo == date)
                XCTAssert(forecast.changeIndicator == nil)
                XCTAssert(forecast.windDirDegrees == 230)
                XCTAssert(forecast.windSpeedKt == 5)
                XCTAssert(forecast.visibilityStatuteMi == 6.21)
                XCTAssert(forecast.wxString == "VCSH")
                
                XCTAssert(forecast.skyCondition[0].skyCover == .sct)
                XCTAssert(forecast.skyCondition[0].cloudBaseFtAgl == 2500)
                XCTAssert(forecast.skyCondition[0].cloudType == nil)
                
                XCTAssert(forecast.skyCondition[1].skyCover == .bkn)
                XCTAssert(forecast.skyCondition[1].cloudBaseFtAgl == 4000)
                XCTAssert(forecast.skyCondition[1].cloudType == nil)

                //Second forecast group
                forecast = taf.forecast[1]
                date = formatter.date(from: "2022-12-07T20:00:00Z")
                XCTAssert(forecast.fcstTimeFrom == date)
                date = formatter.date(from: "2022-12-08T06:00:00Z")
                XCTAssert(forecast.fcstTimeTo == date)
                XCTAssert(forecast.changeIndicator == .fm)

                XCTAssert(forecast.windDirDegrees == 110)
                XCTAssert(forecast.windSpeedKt == 10)
                XCTAssert(forecast.visibilityStatuteMi == 6.21)
                XCTAssert(forecast.wxString == "VCSH")
                
                XCTAssert(forecast.skyCondition[0].skyCover == .sct)
                XCTAssert(forecast.skyCondition[0].cloudBaseFtAgl == 2500)
                XCTAssert(forecast.skyCondition[0].cloudType == nil)
                
                XCTAssert(forecast.skyCondition[1].skyCover == .bkn)
                XCTAssert(forecast.skyCondition[1].cloudBaseFtAgl == 4000)
                XCTAssert(forecast.skyCondition[1].cloudType == nil)

                //Third forecast group
                forecast = taf.forecast[2]
                date = formatter.date(from: "2022-12-08T06:00:00Z")
                XCTAssert(forecast.fcstTimeFrom == date)
                date = formatter.date(from: "2022-12-08T18:00:00Z")
                XCTAssert(forecast.fcstTimeTo == date)
                XCTAssert(forecast.changeIndicator == .fm)

                XCTAssert(forecast.windDirDegrees == 250)
                XCTAssert(forecast.windSpeedKt == 7)
                XCTAssert(forecast.visibilityStatuteMi == 6.21)
                XCTAssert(forecast.wxString == "VCSH")
                
                XCTAssert(forecast.skyCondition[0].skyCover == .sct)
                XCTAssert(forecast.skyCondition[0].cloudBaseFtAgl == 2500)
                XCTAssert(forecast.skyCondition[0].cloudType == nil)
                
                XCTAssert(forecast.skyCondition[1].skyCover == .bkn)
                XCTAssert(forecast.skyCondition[1].cloudBaseFtAgl == 4000)
                XCTAssert(forecast.skyCondition[1].cloudType == nil)

                
                // check second, later TAF and make sure it's index is 1
                let secondDate = formatter.date(from: "2022-12-07T11:38:00Z")
                XCTAssert(testTAFs[1].issueTime == secondDate)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }
    
    
    
    func testAsyncTAF() async throws {
        
        let client = ADDSClient()
        //These 6 stations should always hava TAF available...
        let request = TAFRequest(forStations: ["ESSA", "ENGM", "GCLP", "LFPG", "KJFK", "KLAX"], mostRecent: true)

        do {
            let tafs = try await client.send(request)
            XCTAssert(tafs.count == 6, "Error getting tafs")
        } catch {
            XCTFail("Error thrown getting tafs: \(ADDSClient.messageIn(error))")
        }
    }
}
