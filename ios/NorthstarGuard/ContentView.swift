import SwiftUI

@MainActor final class DashboardModel: ObservableObject {
    @Published var status: NorthstarStatus?
    @Published var report: LatestReport?
    @Published var error = ""
    @Published var refreshing = false
    var url: String { UserDefaults.standard.string(forKey: "northstar.apiURL") ?? "" }
    func refresh() async {
        guard !url.isEmpty else { error = "Open Settings to connect Northstar."; return }
        refreshing = true; defer { refreshing = false }
        do { let api = NorthstarAPI(baseURL: url); async let s = api.status(); async let r = api.latestReport(); status = try await s; report = try await r; error = "" }
        catch let failure { error = failure.localizedDescription }
    }
}

struct ContentView: View {
    @StateObject private var model = DashboardModel()
    @State private var settings = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Text("Fleet status").font(.largeTitle.bold()); Spacer(); Button("Settings") { settings = true } }
                    HStack(spacing: 12) { Metric(title: "Runner", value: model.status?.backendState ?? "—"); Metric(title: "Online", value: model.status?.controlPlane?.onlineCount.map(String.init) ?? "—"); Metric(title: "Devices", value: model.status?.controlPlane?.deviceCount.map(String.init) ?? "—") }
                    GroupBox { VStack(alignment: .leading) { HStack { Text("Latest report").font(.headline); Spacer(); Button("Refresh") { Task { await model.refresh() } }.disabled(model.refreshing) }; if let report = model.report, report.available { Text(report.filename ?? "").font(.caption).foregroundStyle(.secondary); Text(report.markdown ?? "").font(.system(.body, design: .monospaced)).textSelection(.enabled) } else { Text(model.error.isEmpty ? "No report available." : model.error).foregroundStyle(.secondary) } }.frame(maxWidth: .infinity, alignment: .leading) }
                }.padding()
            }.navigationBarHidden(true).task { await model.refresh() }.refreshable { await model.refresh() }
        }.sheet(isPresented: $settings) { SettingsView { settings = false; Task { await model.refresh() } } }
    }
}

struct Metric: View { let title: String; let value: String; var body: some View { VStack(alignment: .leading) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.bold()) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14)) } }

struct SettingsView: View {
    let done: () -> Void
    @State private var url = UserDefaults.standard.string(forKey: "northstar.apiURL") ?? ""
    var body: some View { NavigationStack { Form { Section("Northstar API") { TextField("Tailscale Serve URL", text: $url).keyboardType(.URL).textInputAutocapitalization(.never); Text("Access is provided by the authorized Tailscale connection. This app stores no Northstar credentials.").font(.footnote).foregroundStyle(.secondary) } }.navigationTitle("Settings").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { UserDefaults.standard.set(url.trimmingCharacters(in: CharacterSet(charactersIn: "/")), forKey: "northstar.apiURL"); done() } } } } }
}
