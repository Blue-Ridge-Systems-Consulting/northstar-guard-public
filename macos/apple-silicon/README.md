# Northstar Guard for Apple Silicon Macs

This is the native arm64 package for Apple Silicon Macs (M1, M2, M3, M4, and later). It uses the same tested Northstar Guard engine and AppKit dashboard as the macOS package, compiled explicitly for `arm64`.

## Install

From a checkout of this repository:

```zsh
chmod +x macos/apple-silicon/install-northstar-guard.sh
macos/apple-silicon/install-northstar-guard.sh
```

The installer requires macOS 12 or newer and Apple Command Line Tools. It installs the app at `~/Applications/Northstar Guard.app`, runs the monitor as the current user’s LaunchAgent, and keeps reports under `~/NorthstarGuardReports` unless `NORTHSTAR_GUARD_REPORT_DIR` or `--reports-dir` is supplied.

The dashboard may be closed without stopping monitoring. Use the dashboard’s controls or the installer’s `--repair`, `--status`, `--upgrade`, and `--uninstall` actions to manage the agent.

## Scope and engines

The monitor remains lightweight and focused. It checks the user’s Downloads, Desktop, Documents, startup/login persistence locations, and selected temporary paths; it does not scan the entire disk. Detection uses downloaded executable heuristics, Apple quarantine metadata, misleading double-extension checks, macOS Security framework signature validation, and persistence-baseline checks. It is a clean-room monitor and does not use ClamAV or Bitdefender signatures.

Apple Silicon reports also include a read-only platform posture section: native `arm64` execution, Secure Enclave service presence, FileVault state, System Integrity Protection state, and Gatekeeper assessment state. These checks do not change security settings or require administrator credentials.

The source is shared with [`../Sources`](../Sources) and [`../Tools`](../Tools) so the tested macOS behavior stays consistent while this package produces native Apple Silicon binaries.
