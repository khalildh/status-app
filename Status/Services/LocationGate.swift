import Foundation
import CoreLocation

@Observable
final class LocationGate: NSObject {
    var isInNYC = false
    var isChecking = true
    var denied = false

    @ObservationIgnored private var locationManager = CLLocationManager()

    // NYC bounding box (generous — covers all 5 boroughs + some buffer)
    private static let nycRegion = (
        minLat: 40.49,
        maxLat: 40.92,
        minLon: -74.26,
        maxLon: -73.70
    )

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func checkLocation() {
        isChecking = true
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            denied = true
            isChecking = false
        @unknown default:
            isChecking = false
        }
    }

    private func evaluate(_ location: CLLocation) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let nyc = Self.nycRegion
        isInNYC = lat >= nyc.minLat && lat <= nyc.maxLat && lon >= nyc.minLon && lon <= nyc.maxLon
        isChecking = false
    }

    static var preview: LocationGate {
        let gate = LocationGate()
        gate.isInNYC = true
        gate.isChecking = false
        return gate
    }
}

extension LocationGate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        evaluate(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isChecking = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            denied = true
            isChecking = false
        default:
            break
        }
    }
}
