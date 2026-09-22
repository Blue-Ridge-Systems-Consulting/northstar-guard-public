# Northstar Agent Contract v1

This contract is the shared boundary between Northstar agents and future dashboards. Agents remain local-first; the contract describes data, not a required transport. A client may read these objects from local files, an authenticated API, or a private connected relay.

## Compatibility rules

- Every object carries `schemaVersion` (`1.0`). Readers must accept newer minor versions and ignore unknown fields.
- `agentId` is a stable installation identifier. It must not be derived from a changing hostname or IP address.
- Timestamps are RFC 3339 with an explicit offset or `Z`.
- Paths are native absolute paths on the host that produced the finding. They are not interpreted on another host.
- Findings are append-only JSON Lines. Status is a replaceable snapshot. Scan requests are short-lived commands with an idempotency key.
- Agents never upload file contents by default. Hashes and metadata are preferred; content transfer requires an explicit user action.
- Severity is one of `INFO`, `LOW`, `MEDIUM`, `HIGH`, or `CRITICAL`.

## Objects

### Status snapshot

`status.json` describes the current agent and latest scan. Required fields are `schemaVersion`, `agentId`, `agentVersion`, `platform`, `host`, `monitoring`, `scanInProgress`, `findings`, `trustedExclusions`, `updatedAt`, and `capabilities`. See `schemas/status.schema.json`.

### Finding event

`findings.jsonl` contains one object per detection. Required fields are `schemaVersion`, `findingId`, `agentId`, `detectedAt`, `severity`, `category`, `path`, `engines`, `reasons`, and `state`. `state` is `active`, `trusted`, `resolved`, or `suppressed`. See `schemas/finding.schema.json`.

### Scan request

Clients request `focused`, `full`, or `path` scans. A request includes `requestId`, `requestedAt`, `requestedBy`, and an optional path. Agents must record the request ID in status/report metadata and must not run two identical request IDs concurrently. See `schemas/scan-request.schema.json`.

### Trusted item

Trusted entries should identify the path and trust time, and should include a SHA-256 when the platform can calculate one. Path-only trust remains supported for legacy agents, but hash-plus-path trust is preferred. See `schemas/trusted-item.schema.json`.

### Report manifest

Each Markdown report may have a companion manifest carrying normalized counts, scope, engines, and the Markdown path. See `schemas/report.schema.json`.

## Migration mapping

Existing Mac `status.json`, Windows `status.json`, and Linux `status` files can be wrapped into a v1 status snapshot without changing scan behavior. Existing flat finding records map as follows: `date` → `detectedAt`, `severity` stays `severity`, `reasons` stays `reasons`, and the producer supplies `findingId`, `agentId`, `category`, `engines`, and `state`. Existing historical records remain valid evidence and do not need rewriting.

## Report metadata

Markdown reports should include a `Contract` line containing `Northstar Agent Contract v1.0`, plus the agent ID, scan request ID (when applicable), generated timestamp, scope, examined count, finding count, trusted count, skipped/error count, and engine list. Markdown remains the human-readable format; these fields make reports machine-indexable.
