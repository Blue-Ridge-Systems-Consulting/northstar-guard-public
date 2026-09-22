# Northstar Guard

<p align="center"><img src="assets/blue-ridge-systems-consulting-logo.svg" alt="Blue Ridge Systems Consulting" width="360"></p>

<p align="center">A lightweight, local-first security monitor for macOS, Apple Silicon, Fedora COSMIC, headless Linux, Windows, and iOS/iPadOS.</p>

Northstar Guard is a clean-room, monitor-only security toolkit. It focuses on high-value locations, explains why an item was reported, writes timestamped Markdown reports, and leaves remediation decisions with the operator. It does not claim to replace a commercial antivirus product.

## Platform packages

| Platform | Package | Install |
| --- | --- | --- |
| Intel macOS | [macos/](macos/) | `zsh macos/install-northstar-guard.sh` |
| Apple Silicon macOS | [macos/apple-silicon/](macos/apple-silicon/) | `zsh macos/apple-silicon/install-northstar-guard.sh` |
| Fedora COSMIC | [fedora-cosmic/](fedora-cosmic/) | `bash fedora-cosmic/install.sh` |
| Headless Linux / Rocky Linux | [server-headless/](server-headless/) | `sudo bash server-headless/install.sh` |
| Windows 10 / 11 / Server | [windows/](windows/) | `powershell -ExecutionPolicy Bypass -File windows/install-northstar-guard.ps1` |

Each package has its own platform README and installer. Installers use the current user or service account and do not assume a specific private username, network, or fleet.

## What it scans

Northstar uses focused, configurable scopes rather than crawling every file on a computer. Depending on the platform, coverage includes user Downloads/Desktop/Documents, temporary directories, startup and persistence locations, local executable paths, and selected system service locations. Large files, hidden package descendants, and missing paths are bounded or skipped as documented by each package.

Detection is evidence-based and monitor-only: downloaded executable heuristics, quarantine metadata, misleading extensions, platform signature validation, persistence baselines, YARA rules, and optional ClamAV integration for the headless Linux package. It does not delete or quarantine files automatically.

## Reports and trusted findings

Reports are timestamped Markdown with an executive summary, scan coverage, findings, recommendations, and data gaps. Operators can explicitly mark known-good findings as trusted. Trust is a local allow-list decision, not a malware verdict.

## Screenshots

The [`screenshots/`](screenshots/) directory contains representative dashboard and platform views.

## Building and testing

Install the platform’s normal build prerequisites, then use the package README and build scripts. The Apple Silicon package compiles native `arm64` binaries and adds read-only Apple platform posture checks such as FileVault, SIP, Gatekeeper, and Secure Enclave service presence.

The update tooling in [`macos/update-channel/`](macos/update-channel/) creates and verifies versioned source bundles. It does not contain fleet credentials or deployment configuration.

## Security and privacy

See [SECURITY.md](SECURITY.md). Do not place API keys, OAuth credentials, SSH keys, private certificates, production hostnames, private reports, or personal data in issues, pull requests, screenshots, or this repository.

Northstar Guard is released under the Apache-2.0 license.
