import Foundation

struct NorthstarAPI {
    var baseURL: String
    private func request(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url); req.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return data
    }
    func status() async throws -> NorthstarStatus { try JSONDecoder().decode(NorthstarStatus.self, from: await request("/api/v1/status")) }
    func latestReport() async throws -> LatestReport {
        let index = try JSONDecoder().decode(ReportIndex.self, from: await request("/api/v1/reports"))
        guard let id = index.reports.first?.id, let escaped = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return LatestReport(available: false, filename: nil, markdown: nil)
        }
        return try JSONDecoder().decode(LatestReport.self, from: await request("/api/v1/reports/\(escaped)"))
    }
}
