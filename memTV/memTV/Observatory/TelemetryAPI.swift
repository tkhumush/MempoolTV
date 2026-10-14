import Foundation

struct TelemetryAPI: Sendable {
    let client: any NetworkClient
    init(client: any NetworkClient = URLSessionNetworkClient()) { self.client = client }
    func get<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        guard let url = URL(string: "https://mempool.space/api/" + path) else { throw NetworkError.invalidURL }
        for attempt in 0...3 {
            try Task.checkCancellation()
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await client.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            if http.statusCode == 429, attempt < 3 {
                let delay = Self.retryDelay(http.value(forHTTPHeaderField: "Retry-After"), attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1e9))
                continue
            }
            guard (200...299).contains(http.statusCode) else { throw NetworkError.httpError(http.statusCode) }
            return try JSONDecoder().decode(T.self, from: data)
        }
        throw NetworkError.rateLimited
    }
    static func retryDelay(_ header: String?, attempt: Int, now: Date = Date()) -> Double {
        if let header {
            if let seconds = Double(header), seconds.isFinite { return min(300, max(1, seconds)) }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
            if let date = formatter.date(from: header) { return min(300, max(1, date.timeIntervalSince(now))) }
        }
        return min(30, pow(2, Double(attempt)))
    }
}
