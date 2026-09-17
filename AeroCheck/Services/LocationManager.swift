//
//  LocationManager.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Modern CoreLocation coordinator using the `@Observable` macro for seamless SwiftUI binding.
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    public var coordinate: CLLocationCoordinate2D?
    public var altitudeMeters: Double?
    public var placemarkName: String = "Locating drone launch site..."
    public var streetAddress: String = ""
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var isLocating: Bool = false
    public var errorMessage: String?

    private let manager = CLLocationManager()

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    /// Requests When-In-Use authorization and one-shot location update.
    public func requestCurrentLocation() {
        isLocating = true
        errorMessage = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            isLocating = false
            errorMessage = "Location access denied. Enable Location Services in iOS Settings or enter coordinates manually."
            // Fallback to default if no coordinate yet
            if coordinate == nil {
                setManualCoordinate(latitude: 37.7749, longitude: -122.4194, name: "San Francisco, CA (Default)")
            }
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            manager.requestWhenInUseAuthorization()
        }
    }

    /// Sets coordinates manually (e.g. for mission planning or pin drop).
    public func setManualCoordinate(latitude: Double, longitude: Double, name: String? = nil) {
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.coordinate = coord
        if let explicitName = name {
            self.placemarkName = explicitName
            self.streetAddress = explicitName
        } else {
            reverseGeocode(coordinate: coord)
        }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLocating = false
            errorMessage = "Location permissions restricted. Using manual mission coordinates."
            if coordinate == nil {
                setManualCoordinate(latitude: 37.7749, longitude: -122.4194, name: "San Francisco, CA (Default)")
            }
        default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        isLocating = false
        self.coordinate = location.coordinate
        self.altitudeMeters = location.altitude > 0 ? location.altitude : 10.0
        reverseGeocode(coordinate: location.coordinate)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        // Ignore temporary CLError.locationUnknown
        if let clErr = error as? CLError, clErr.code == .locationUnknown {
            return
        }
        self.errorMessage = "Unable to resolve GPS fix: \(error.localizedDescription)"
        if coordinate == nil {
            setManualCoordinate(latitude: 37.7749, longitude: -122.4194, name: "San Francisco, CA (Default)")
        }
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: clLocation) else {
            self.placemarkName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            self.streetAddress = self.placemarkName
            return
        }

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let mapItems = try await request.mapItems
                if let item = mapItems.first {
                    let name = item.name ?? ""
                    let address = item.address?.shortAddress ?? item.address?.fullAddress ?? ""

                    var displayParts: [String] = []
                    if !name.isEmpty {
                        displayParts.append(name)
                    }
                    if !address.isEmpty && address != name {
                        displayParts.append(address)
                    }

                    let fullText = displayParts.joined(separator: ", ")
                    self.placemarkName = fullText.isEmpty ? String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude) : fullText
                    self.streetAddress = fullText
                } else {
                    self.placemarkName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    self.streetAddress = self.placemarkName
                }
            } catch {
                self.placemarkName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                self.streetAddress = self.placemarkName
            }
        }
    }
}
