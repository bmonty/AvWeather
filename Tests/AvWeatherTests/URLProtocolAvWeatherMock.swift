
import Foundation

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

//Using JSON instead of XML
class URLProtocolSigmetMock: URLProtocolAvWeatherMock {

    override func startLoading() {
        if let url = request.url {
            let headers: [String: String] = [
                "Content-Type": "application/json",
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
}
