//
//  ViewController.swift
//  AvWeather-Example
//
//  Created by Johan Nyman on 2022-12-07.
//

import UIKit
import AvWeather

class WeatherViewController: UIViewController {

    private let weatherClient = AWCClient()
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var resultView: UITextView!
    @IBOutlet var hoursLabel: UILabel!
    @IBOutlet var recentSwitch: UISwitch!
    
    private var hoursBack: Int = 12
    
    /// send a request for METAR data at stations given in the textfield
    @IBAction func getMetars() {
        let stations: [String] = textField.text?.components(separatedBy: ",") ?? []
        weatherClient.send(MetarRequest(forStations: stations, hoursBeforeNow: hoursBack, mostRecent: recentSwitch.isOn)) { [weak self] response in
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
                    let msg = AWCClient.messageIn(error)
                    self?.resultView.text.append("\(msg)\n")
                }
            }
        }
    }

    /// send a request for TAF data at stations given in the textfield
    @IBAction func getTafs() {
        let stations: [String] = textField.text?.components(separatedBy: ",") ?? []
        weatherClient.send(TAFRequest(forStations: stations, hoursBeforeNow: hoursBack, mostRecent: recentSwitch.isOn)) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let tafs):
                    tafs.forEach { taf in
                        self?.resultView.text.append("\(taf.rawText)\n")
                    }
                    
                case .failure(let error):
                    // request failed
                    self?.resultView.text.append("Failed to get tafs: \n")
                    let msg = AWCClient.messageIn(error)
                    self?.resultView.text.append("\(msg)\n")
                }
            }
        }
    }
    
    /// Send a request for International Sigmet data
    @IBAction func getIntlSigmets() {
        weatherClient.send(SigmetRequest(type: .international)) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let sigmets):
                    self?.resultView.text.append("***   \(sigmets.count) Sigmets retrieved:   ***\n\n")
                    sigmets.forEach { sigmet in
                        self?.resultView.text.append("\(sigmet.properties.rawSigmet ?? sigmet.properties.rawAirSigmet ?? "[no text]")\n\n")
                    }
                    
                case .failure(let error):
                    // request failed
                    self?.resultView.text.append("Failed to get sigmets: \n")
                    let msg = AWCClient.messageIn(error)
                    self?.resultView.text.append("\(msg)\n")
                }
            }
        }
    }

    /// Send a request for US Sigmet data
    @IBAction func getUSSigmets() {
        weatherClient.send(SigmetRequest(type: .usOnly)) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let sigmets):
                    self?.resultView.text.append("***   \(sigmets.count) Sigmets retrieved:   ***\n\n")
                    sigmets.forEach { sigmet in
                        self?.resultView.text.append("\(sigmet.properties.rawSigmet ?? sigmet.properties.rawAirSigmet ?? "[no text]")\n\n")
                    }
                    
                case .failure(let error):
                    // request failed
                    self?.resultView.text.append("Failed to get sigmets: \n")
                    let msg = AWCClient.messageIn(error)
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

