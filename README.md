# AvWeather

AvWeather is a Swift package allowing you to retrieve and use data from [aviationweather.gov](https://www.aviationweather.gov).

# Usage

(The example shows Metar, but TAF can be used as well)

```swift
import AvWeather

let avWeatherClient = ADDSClient()

// send a request for METAR data for Boston Logan Airport (KBOS)
avWeatherClient.send(MetarRequest(forStation: "KBOS")) { response in 
    switch response {
    case .success(let metars):
        // do something with new METAR data
        print(metars[0].rawText)
        
    case .failure(let error):
        // request failed
        print(error.localizedDescription)
    }
}

// send a request for METAR data at multiple stations
avWeatherClient.send(MetarRequest(forStations: ["KBOS", "KORD", "KLAX"])) { response in
    switch response {
    case .success(let metars):
        // do something with new METAR data
        print(metars[0].rawText)
        
    case .failure(let error):
        // request failed
        print(error.localizedDescription)
    }
}
```
## Async/Await

AvWeather can also be used in Swift Async/Await concurrency schemes:

(The example shows TAF, but Metar can be used as well)

```
// Instantiate a client
let client = ADDSClient()
// Configure the request using 1 or more stations
let request = TAFRequest(forStations: ["ESSA", "ENGM", "GCLP", "LFPG", "KJFK", "KLAX"], mostRecent: true)
do {
    let tafs = try await client.send(request)
    // do something with TAF data
    print(tafs[0].rawText)
} catch {
    // An error was thrown
    print("Error thrown getting tafs: \(ADDSClient.messageIn(error))")
}
```
