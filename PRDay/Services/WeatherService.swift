import Foundation
import CoreLocation
import WeatherKit

struct WeatherSnapshot: Equatable, Codable {
    let tempF: Double
    let humidity: Double
    let condition: String
    let fetchedAt: Date

    var isFresh: Bool {
        Date.now.timeIntervalSince(fetchedAt) < 3 * 3600
    }
}

@MainActor
final class WeatherProvider: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = WeatherProvider()

    @Published var snapshot: WeatherSnapshot?
    @Published var flag: HeatFlag?
    @Published var usingFallback = false

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?
    private let cacheKey = "weatherCache"

    private override init() {
        super.init()
        manager.delegate = self
        loadCache()
    }

    func refresh() async {
        if let cached = cachedFresh() {
            apply(snapshot: cached, fallback: false)
        }
        do {
            guard let location = await requestLocation() else {
                applyFallback()
                return
            }
            let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
            let current = weather.currentWeather
            let snap = WeatherSnapshot(
                tempF: current.temperature.converted(to: .fahrenheit).value,
                humidity: current.humidity * 100,
                condition: current.condition.description,
                fetchedAt: Date.now
            )
            saveCache(snap)
            apply(snapshot: snap, fallback: false)
        } catch {
            applyFallback()
        }
    }

    private func apply(snapshot: WeatherSnapshot, fallback: Bool) {
        self.snapshot = snapshot
        self.usingFallback = fallback
        self.flag = WBGTEngine.compute(tempF: snapshot.tempF, humidity: snapshot.humidity).flag
    }

    private func applyFallback() {
        if let cached = cachedAny() {
            apply(snapshot: cached, fallback: true)
        } else {
            usingFallback = true
            flag = nil
        }
    }

    private func cachedFresh() -> WeatherSnapshot? {
        guard let cached = cachedAny(), cached.isFresh else { return nil }
        return cached
    }

    private func cachedAny() -> WeatherSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
    }

    private func saveCache(_ snap: WeatherSnapshot) {
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCache() {
        snapshot = cachedAny()
    }

    private func requestLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        if status == .denied || status == .restricted {
            return nil
        }
        return await withCheckedContinuation { cont in
            continuation = cont
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.continuation?.resume(returning: locations.first)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(returning: nil)
            self.continuation = nil
        }
    }
}
