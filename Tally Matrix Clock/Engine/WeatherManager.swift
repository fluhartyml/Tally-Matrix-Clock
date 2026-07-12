//
//  WeatherManager.swift
//  CryoKit
//
//  Created by Michael Fluharty on 3/31/26.
//

import Foundation
import WeatherKit
import CoreLocation

@Observable
public class CryoWeatherManager: NSObject, CLLocationManagerDelegate {
    public var temperature: String = "--"
    public var condition: String = ""
    public var locationName: String = ""

    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastLocation: CLLocation?

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    public func requestWeather() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        lastLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality {
                Task { @MainActor in
                    self?.locationName = city
                }
            }
        }

        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                let temp = Int(weather.currentWeather.temperature.converted(to: .fahrenheit).value)
                let cond = weather.currentWeather.condition.description
                await MainActor.run {
                    self.temperature = "\(temp)°F"
                    self.condition = cond
                }
            } catch {
                print("Weather error: \(error)")
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
