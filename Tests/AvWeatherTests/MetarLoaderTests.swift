import XCTest
@testable import AvWeather

class URLProtocolMetarMockSuccess: URLProtocol {

    static var testURLs = [URL?: Data]()

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
            if let data = URLProtocolMetarMockSuccess.testURLs[url] {
                self.client?.urlProtocol(self, didLoad: data)
            }
        }

        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }

}

class MetarLoaderSpyDelegate: MetarLoaderDelegate {

    var result: MetarLoader?
    var error: MetarLoaderError?
    var asyncExpectation: XCTestExpectation?

    func metarLoaded(_ metarLoader: MetarLoader, didDownloadMetars metars: [Metar]) {
        guard let expectation = asyncExpectation else {
            XCTFail("MetarLoaderSpyDelegate was not set up correctly. Missing XCTExpectation reference.")
            return
        }

        self.result = metarLoader
        expectation.fulfill()
    }

    func metarLoaded(_ metarLoader: MetarLoader, didFailDownloadWithError error: MetarLoaderError) {
        guard let expectation = asyncExpectation else {
            XCTFail("MetarLoaderSpyDelegate was not set up correctly. Missing XCTExpectation reference.")
            return
        }

        self.error = error
        expectation.fulfill()
    }
}

final class MetarLoaderTests: XCTestCase {

    func testMetarLoadSuccess() {
        let url = URL(string: "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=KFME&hoursBeforeNow=2")

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/fme_metars.xml")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolMetarMockSuccess.testURLs = [url: data]

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolMetarMockSuccess.self]

            let session = URLSession(configuration: config)

            let metarLoader = MetarLoader(forIcaoId: "KFME", session: session)
            let spyDelegate = MetarLoaderSpyDelegate()
            metarLoader.delegate = spyDelegate

            let expect = expectation(description: "MetarLoader calls the delegate as the result of an async method completion.")
            spyDelegate.asyncExpectation = expect

            metarLoader.getData()

            waitForExpectations(timeout: 1) { error in
                if let error = error {
                    XCTFail("waitForExpectations error occurred: \(error)")
                }

                guard let result = spyDelegate.result else {
                    XCTFail("Expected result to be set.")
                    return
                }

                XCTAssert(result.id == "KFME")
                XCTAssert(result.metars.count == 2)

                let metar = result.metars[0]
                XCTAssert(metar.rawText == "KFME 201348Z AUTO 33006KT 10SM CLR M04/M10 A3037 RMK AO1")
                XCTAssert(metar.stationId == "KFME")
                let formatter = ISO8601DateFormatter()
                let date = formatter.date(from: "2020-01-20T13:48:00Z")
                XCTAssert(metar.observationTime == date)
                XCTAssert(metar.latitude == 39.08)
                XCTAssert(metar.longitude == -76.77)
                XCTAssert(metar.tempC == -4.0)
                XCTAssert(metar.dewpointC == -10.0)
                XCTAssert(metar.windDirDegrees == 330)
                XCTAssert(metar.windSpeed == 6)
                XCTAssert(metar.windGust == Int.max)
                XCTAssert(metar.visibility == 10.0)
                XCTAssert(metar.altimeter == 30.369095)
                XCTAssert(metar.seaLevelPressure.isNaN)
                XCTAssert(metar.skyCondition.count == 1)
                XCTAssert(metar.flightCategory == "VFR")
                XCTAssert(metar.threeHourPressureTendency.isNaN)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }

    func testMetarLoadBadIcaoId() {
        let url = URL(string: "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=KXXX&hoursBeforeNow=2")

        let sourceFile = URL(fileURLWithPath: #file)
        let directory = sourceFile.deletingLastPathComponent()
        let testDataURL = directory.appendingPathComponent("TestData/bad_id.xml")
        do {
            let data = try Data(contentsOf: testDataURL)

            URLProtocolMetarMockSuccess.testURLs = [url: data]

            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [URLProtocolMetarMockSuccess.self]

            let session = URLSession(configuration: config)

            let metarLoader = MetarLoader(forIcaoId: "KXXX", session: session)
            let spyDelegate = MetarLoaderSpyDelegate()
            metarLoader.delegate = spyDelegate

            let expect = expectation(description: "MetarLoader calls the delegate as the result of an async method completion.")
            spyDelegate.asyncExpectation = expect

            metarLoader.getData()

            waitForExpectations(timeout: 1) { error in
                if let error = error {
                    XCTFail("waitForExpectations error occurred: \(error)")
                }

                guard let metarError = spyDelegate.error else {
                    XCTFail("Expected error to be set")
                    return
                }

                XCTAssert(metarError.message == "Invalid ICAO ID.")
                XCTAssert(metarError.kind == .invalidIcaoId)
            }
        } catch {
            XCTFail("Failed to load test data: \(error)")
        }
    }

    static var allTests = [
        ("testMetarLoadSuccess", testMetarLoadSuccess),
        ("testMetarLoadBadIcaoId", testMetarLoadBadIcaoId),
    ]
}
