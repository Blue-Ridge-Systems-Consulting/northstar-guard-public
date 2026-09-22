import Foundation

struct NorthstarStatus: Decodable {
    let backendState: String?
    let controlPlane: ControlPlane?
    enum CodingKeys: String, CodingKey { case backendState = "backend_state"; case controlPlane = "control_plane" }
}
struct ControlPlane: Decodable { let deviceCount: Int?; let onlineCount: Int?; enum CodingKeys: String, CodingKey { case deviceCount = "device_count"; case onlineCount = "online_count" } }
struct LatestReport: Decodable { let available: Bool; let filename: String?; let markdown: String? }
struct ReportIndex: Decodable { let reports: [ReportSummary] }
struct ReportSummary: Decodable { let id: String; let filename: String; let modified: Double }
