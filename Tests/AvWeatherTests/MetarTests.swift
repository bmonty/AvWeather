import XCTest
@testable import AvWeather

class URLProtocolAvWeatherMock: URLProtocol {

    static var testURLs = [String: Data]()

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let url = request.url {
            let headers: [String: String] = [
                "Content-Type": "text/xml",
            ]
            if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            let urlString = String(url.absoluteString.split(separator: "?")[0])
            if let data = URLProtocolAvWeatherMock.testURLs[urlString] {
                self.client?.urlProtocol(self, didLoad: data)
            }
        }

        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }

}

final class MetarTests: XCTestCase {

    func testMetarLoadSingleStation() {
        let url = "https://aviationweather.gov/adds/dataserver_current/httpparam"

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/fme_metars.xml")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolAvWeatherMock.testURLs = [url: data]
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolAvWeatherMock.self]

            let session = URLSession(configuration: config)

            let client = ADDSClient(session: session)
            let request = MetarRequest(forStation: "KFME")

            let expect = expectation(description: "Got MetarRequestData")
            var testMetars: [Metar] = []

            client.send(request) { response in
                switch response {
                case .success(let metars):
                    testMetars = metars
                    expect.fulfill()

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }

            waitForExpectations(timeout: 2) { error in
                if let error = error {
                    XCTFail("MetarRequest waiting failed: \(error)")
                    return
                }

                // check latest METAR is index 0, and data is correct
                let metar = testMetars[0]
                XCTAssert(metar.rawText == "KFME 201348Z AUTO 33006KT 10SM CLR M04/M10 A3037 RMK AO1")
                XCTAssert(metar.stationId == "KFME")
                let formatter = ISO8601DateFormatter()
                let date = formatter.date(from: "2020-01-20T13:48:00Z")
                XCTAssert(metar.observationTime == date)
                XCTAssert(metar.latitude == 39.08)
                XCTAssert(metar.longitude == -76.77)
                XCTAssert(metar.temp == -4.0)
                XCTAssert(metar.dewpoint == -10.0)
                XCTAssert(metar.windDirection == 330)
                XCTAssert(metar.windSpeed == 6)
                XCTAssert(metar.windGust == 0)
                XCTAssert(metar.visibility == 10.0)
                XCTAssert(metar.altimeter == 30.369095)
                XCTAssert(metar.seaLevelPressure == 0.0)
                XCTAssert(metar.skyCondition.count == 1)
                XCTAssert(metar.flightCategory == .vfr)
                XCTAssert(metar.threeHourPressureTendency == 0.0)

                // check second, later METAR and make sure it's index is 1
                let secondDate = formatter.date(from: "2020-01-20T13:27:00Z")
                XCTAssert(testMetars[1].observationTime == secondDate)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }

    func testMetarLoadMultipleStations() {
        let url = "https://aviationweather.gov/adds/dataserver_current/httpparam"

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/multiple.xml")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolAvWeatherMock.testURLs = [url: data]
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolAvWeatherMock.self]

            let session = URLSession(configuration: config)

            let client = ADDSClient(session: session)
            let request = MetarRequest(forStations: ["KFME", "KFDK", "KBWI"])

            let expect = expectation(description: "Got MetarRequestData")
            var testMetars: [Metar] = []

            client.send(request) { response in
                switch response {
                case .success(let metars):
                    testMetars = metars
                    expect.fulfill()

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }

            waitForExpectations(timeout: 2) { error in
                if let error = error {
                    XCTFail("MetarRequest waiting failed: \(error)")
                    return
                }

                XCTAssert(testMetars.count == 20)

                // KFME == 12
                var countFME = 0, countFDK = 0, countBWI = 0
                for metar in testMetars {
                    switch metar.stationId {
                    case "KFME":
                        countFME += 1
                    case "KFDK":
                        countFDK += 1
                    case "KBWI":
                        countBWI += 1
                    default:
                        XCTFail("Unknown station in results.")
                    }
                }
                XCTAssert(countFME == 12)
                XCTAssert(countFDK == 4)
                XCTAssert(countBWI == 4)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }

    func testMetarLoadBadIcaoId() {
        let url = "https://aviationweather.gov/adds/dataserver_current/httpparam"

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/bad_id.xml")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolAvWeatherMock.testURLs = [url: data]

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolAvWeatherMock.self]

            let session = URLSession(configuration: config)

            let client = ADDSClient(session: session)
            let request = MetarRequest(forStation: "KXXX")

            let expect = expectation(description: "Got MetarRequestData")
            var testError: AvWeatherError?

            client.send(request) { response in
                switch response {
                case .success:
                    XCTFail("Expected to get an error.")
                case .failure(let error):
                    testError = error as? AvWeatherError
                    expect.fulfill()
                }
            }

            waitForExpectations(timeout: 1) { error in
                if let error = error {
                    XCTFail("waitForExpectations error occurred: \(error)")
                }

                XCTAssert(testError != nil)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }
    
    func testAsyncMetar() async throws {
        
        let client = ADDSClient()
        let request = MetarRequest(forStations: ["ESSA", "ENGM", "GCLP"], mostRecent: true)

        do {
            let metars = try await client.send(request)
            XCTAssert(metars.count == 3, "Error getting metars")
        } catch {
            XCTFail("Error thrown getting metars: \(error.localizedDescription)")
        }
    }
    

    static var allTests = [
        ("testMetarLoadSingleStation", testMetarLoadSingleStation),
        ("testMetarLoadMultipleStations", testMetarLoadMultipleStations),
        ("testMetarLoadBadIcaoId", testMetarLoadBadIcaoId),
    ]
}
