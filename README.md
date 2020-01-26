# AvWeather

AvWeather is a Swift package allowing you to retrieve and use data from [aviationweather.com](https://www.aviationweather.com).

# Usage

```swift
import AvWeather

let avWeatherClient = ADDSClient()

// send a request to METAR data for Boston Logan Airport (KBOS)
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
```
