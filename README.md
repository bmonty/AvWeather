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

	public func dataLoaded(_ metarLoader: MetarLoader, error: Error?) {
		if let err = error as? MetarLoaderError {
			print("Error: \(err.message)")
			return
		}

		let metar = metarLoader.metars[0]
		print("\(metar.rawText)")
	}

}
```