# AvWeather

AvWeather is a Swift package allowing you to retrieve and use data from [aviationweather.gov](https://www.aviationweather.gov).

# Usage

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
