import Foundation
import CoreLocation
import Testing
@testable import Status

@Suite("LocationGate")
struct LocationGateTests {

    private func makeLocation(lat: Double, lon: Double) -> CLLocation {
        CLLocation(latitude: lat, longitude: lon)
    }

    // MARK: - NYC Bounding Box

    @Test("Manhattan is in NYC")
    func manhattan() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.7580, lon: -73.9855)) // Times Square
        #expect(gate.isInNYC)
        #expect(!gate.isChecking)
    }

    @Test("Brooklyn is in NYC")
    func brooklyn() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.6782, lon: -73.9442))
        #expect(gate.isInNYC)
    }

    @Test("Bronx is in NYC")
    func bronx() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.8448, lon: -73.8648))
        #expect(gate.isInNYC)
    }

    @Test("Queens is in NYC")
    func queens() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.7282, lon: -73.7949))
        #expect(gate.isInNYC)
    }

    @Test("Staten Island is in NYC")
    func statenIsland() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.5795, lon: -74.1502))
        #expect(gate.isInNYC)
    }

    // MARK: - Outside NYC

    @Test("Los Angeles is not in NYC")
    func losAngeles() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 34.0522, lon: -118.2437))
        #expect(!gate.isInNYC)
    }

    @Test("London is not in NYC")
    func london() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 51.5074, lon: -0.1278))
        #expect(!gate.isInNYC)
    }

    @Test("Philadelphia is not in NYC")
    func philadelphia() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 39.9526, lon: -75.1652))
        #expect(!gate.isInNYC)
    }

    @Test("Boston is not in NYC")
    func boston() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 42.3601, lon: -71.0589))
        #expect(!gate.isInNYC)
    }

    @Test("Trenton NJ is not in NYC")
    func trenton() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.2171, lon: -74.7429))
        #expect(!gate.isInNYC)
    }

    // MARK: - Boundary Cases

    @Test("South boundary of NYC")
    func southBoundary() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.49, lon: -73.95))
        #expect(gate.isInNYC) // Exactly on boundary
    }

    @Test("Just below south boundary")
    func belowSouthBoundary() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.48, lon: -73.95))
        #expect(!gate.isInNYC)
    }

    @Test("North boundary of NYC")
    func northBoundary() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.92, lon: -73.95))
        #expect(gate.isInNYC)
    }

    @Test("Just above north boundary")
    func aboveNorthBoundary() {
        let gate = LocationGate()
        gate.evaluate(makeLocation(lat: 40.93, lon: -73.95))
        #expect(!gate.isInNYC)
    }

    // MARK: - State Management

    @Test("Initial state is checking")
    func initialState() {
        let gate = LocationGate()
        #expect(gate.isChecking)
        #expect(!gate.isInNYC)
        #expect(!gate.denied)
    }

    @Test("evaluate sets isChecking to false")
    func evaluateSetsChecking() {
        let gate = LocationGate()
        #expect(gate.isChecking)
        gate.evaluate(makeLocation(lat: 40.75, lon: -73.99))
        #expect(!gate.isChecking)
    }

    @Test("Preview gate is in NYC and not checking")
    func previewGate() {
        let gate = LocationGate.preview
        #expect(gate.isInNYC)
        #expect(!gate.isChecking)
    }

    // MARK: - Delegate Methods

    @Test("didUpdateLocations evaluates last location")
    func didUpdateLocations() {
        let gate = LocationGate()
        let locations = [
            makeLocation(lat: 34.0, lon: -118.0),  // LA
            makeLocation(lat: 40.75, lon: -73.99),  // NYC (last)
        ]
        gate.locationManager(CLLocationManager(), didUpdateLocations: locations)
        #expect(gate.isInNYC)
    }

    @Test("didUpdateLocations with empty array does nothing")
    func didUpdateLocationsEmpty() {
        let gate = LocationGate()
        gate.locationManager(CLLocationManager(), didUpdateLocations: [])
        #expect(gate.isChecking) // Still checking since nothing happened
    }

    @Test("didFailWithError stops checking")
    func didFailWithError() {
        let gate = LocationGate()
        let error = NSError(domain: "test", code: 1)
        gate.locationManager(CLLocationManager(), didFailWithError: error)
        #expect(!gate.isChecking)
    }
}
