//
//  ViewController.swift
//  AvWeather-Example
//
//  Created by Johan Nyman on 2022-12-07.
//

import UIKit
import AvWeather

class WeatherViewController: UIViewController {

    private let weatherClient = ADDSClient()
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var resultView: UITextView!
    @IBOutlet var hoursLabel: UILabel!
    
    private var hoursBack: Int = 2
    
    /// send a request for METAR data at stations given in the textfield
    @IBAction func getMetars() {
        let stations: [String] = textField.text?.components(separatedBy: ",") ?? []
        weatherClient.send(MetarRequest(forStations: stations, hoursBeforeNow: hoursBack, mostRecent: true)) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let metars):
                    // do something with new METAR data
                    metars.forEach { metar in
                        self?.resultView.text.append("\(metar.rawText)\n")
                    }
                    
                case .failure(let error):
                    // request failed
                    self?.resultView.text.append("Failed to get metars: \n")
                    let msg = self?.weatherClient.messageIn(error) ?? "No self"
                    self?.resultView.text.append("\(msg)\n")
                }
            }
        }
    }

    @IBAction func getTafs() {
        let stations: [String] = textField.text?.components(separatedBy: ",") ?? []
        weatherClient.send(TAFRequest(forStations: stations, hoursBeforeNow: hoursBack, mostRecent: true)) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let tafs):
                    tafs.forEach { taf in
                        self?.resultView.text.append("\(taf.rawText)\n")
                    }
                    
                case .failure(let error):
                    // request failed
                    self?.resultView.text.append("Failed to get tafs: \n")
                    let msg = self?.weatherClient.messageIn(error) ?? "No self"
                    self?.resultView.text.append("\(msg)\n")
                }
            }
        }
    }
    
    @IBAction func clearText() {
        resultView.text = ""
    }
    
    @IBAction func sliderChanged(sender: UISlider) {
        hoursBack = Int(sender.value)
        hoursLabel.text = "Hours back: \(hoursBack)"
    }
}

