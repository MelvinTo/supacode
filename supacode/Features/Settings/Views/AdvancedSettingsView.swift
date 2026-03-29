import ComposableArchitecture
import SwiftUI

struct AdvancedSettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    VStack(alignment: .leading) {
      Form {
        Section("API Server") {
          VStack(alignment: .leading) {
            Toggle(
              "Enable localhost API server",
              isOn: $store.apiServerEnabled
            )
            .help("Start an HTTP API server on localhost for external tool integration")
            Text("Allows external tools and scripts to manage repositories and terminals.")
              .foregroundStyle(.secondary)
              .font(.callout)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          if store.apiServerEnabled {
            HStack {
              Text("Port")
              TextField(
                "Port",
                value: $store.apiServerPort,
                format: .number.grouping(.never)
              )
              .frame(width: 80)
              .textFieldStyle(.roundedBorder)
              .help("TCP port for the API server (requires restart of the server)")
            }
            Text("Listening on http://127.0.0.1:\(store.apiServerPort)/api/v1")
              .foregroundStyle(.secondary)
              .font(.callout)
              .monospaced()
          }
        }

        Section("Advanced") {
          VStack(alignment: .leading) {
            Toggle(
              "Share analytics with Supacode",
              isOn: $store.analyticsEnabled
            )
            .help("Share anonymous usage data with Supacode (requires restart)")
            Text("Anonymous usage data helps improve Supacode.")
              .foregroundStyle(.secondary)
              .font(.callout)
            Text("Requires app restart.")
              .foregroundStyle(.secondary)
              .font(.callout)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          VStack(alignment: .leading) {
            Toggle(
              "Share crash reports with Supacode",
              isOn: $store.crashReportsEnabled
            )
            .help("Share anonymous crash reports with Supacode (requires restart)")
            Text("Anonymous crash reports help improve stability.")
              .foregroundStyle(.secondary)
              .font(.callout)
            Text("Requires app restart.")
              .foregroundStyle(.secondary)
              .font(.callout)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .formStyle(.grouped)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
