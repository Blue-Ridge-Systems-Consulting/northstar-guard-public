# Northstar Guard iPhone/iPad client

This is a read-only SwiftUI dashboard for the Northstar API. It stores only the
API URL in the device's local preferences; no Northstar credentials are
embedded in the app or repository.

Open `NorthstarGuard.xcodeproj` in Xcode, select an iPhone or iPad simulator or
connected device, choose your Personal Team under Signing & Capabilities, and
run. Enter the Tailscale Serve URL in Settings while connected to the authorized
Tailscale network. The app uses the tokenless read-only `/api/v1` surface.
