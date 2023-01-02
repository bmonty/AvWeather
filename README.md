# AvWeather

AvWeather is a Swift package allowing you to retrieve and use data from the Aviation Weather Center at [aviationweather.gov](https://www.aviationweather.gov).

# Usage

(The example shows Metar, but TAF can be used as well)

```swift
import AvWeather

let avWeatherClient = AWCClient()

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

## Sigmets

AWC distinguishes between international and US Sigmets. Both can be retrieved by AvWeather, and represented by one common Sigmet class, although with some different properties. Refer to the implementation in `Sigmet.swift` for details.

```swift
import AvWeather

let weatherClient = AWCClient()

//Configure the request for International or US Sigmets
weatherClient.send(SigmetRequest(type: .international)) { [weak self] response in
    DispatchQueue.main.async {
        switch response {
        case .success(let sigmets):
            //Do something with sigmets
            ...
            
        case .failure(let error):
            // request failed
            let msg = AWCClient.messageIn(error)
            print(msg)
        }
    }
}
```

## Async/Await

AvWeather can also be used in Swift Async/Await concurrency schemes:

(The example shows TAF, but Metar and sigmets can be used as well)

```swift
// Instantiate a client
let client = AWCClient()
// Configure the request using 1 or more stations
let request = TAFRequest(forStations: ["ESSA", "ENGM", "GCLP", "LFPG", "KJFK", "KLAX"], mostRecent: true)
do {
    let tafs = try await client.send(request)
    // do something with TAF data
    print(tafs[0].rawText)
} catch {
    // An error was thrown
    print("Error thrown getting tafs: \(AWCClient.messageIn(error))")
}
```
