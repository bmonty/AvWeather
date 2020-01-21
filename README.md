# AvWeather

AvWeather is a Swift package allowing you to retrieve and use data from [aviationweather.com](https://www.aviationweather.com).

# Usage

```swift
import AvWeather

class AvWeatherClient: MetarLoaderDelegate {
	
	private var metarLoader: MetarLoader

	init() {
		metarLoader = MetarLoader(forIcaoId: "KBOS")
		metarLoader.delegate = self
		metarLoader.getData()
	}

    // called when METAR data has been successfully loaded
    func metarLoaded(_ metarLoader: MetarLoader, didDownloadMetars metars: [Metar]) {
		let metar = metarLoader.metars[0]
		print("\(metar.rawText)")
	}
    
    // called if there was an error loading or parsing METAR data
    func metarLoaded(_ metarLoader: MetarLoader, didFailDownloadWithError error: MetarLoaderError) {
        print ("Error loading METAR: \(error.message)")
    }

}
```
