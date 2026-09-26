# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2026-09-26

### Added

- 21 Conditional Access policy templates (Graph v1.0 JSON) in three levels, report-only by default, with break-glass exclusion.
- `scripts/Import-ConditionalAccessBaseline.ps1`: creates baseline policies in report-only or disabled state, checks the break-glass group, skips existing policies, supports `-WhatIf`.
- `scripts/Export-ConditionalAccessPolicy.ps1`: exports all policies as re-importable JSON plus a Markdown overview, optionally with resolved names.
- Governance baselines (three levels): lifecycle, access packages, access reviews, separation of duties, non-human identities and AI agents.
- Pester tests for all templates and scripts, PSScriptAnalyzer and gitleaks in CI.
- Naming convention, privileged role set and licence overview for Conditional Access.

### Changed

- Conditional Access baselines rewritten: authentication strengths instead of the plain MFA control, app protection instead of the approved-client-app grant, risk responses as Conditional Access policies, new controls for unknown platforms, security info registration, device code flow, authentication transfer, unmanaged-device sessions and workload identities.
- Security controls updated to current Microsoft guidance: break-glass accounts with passkeys or certificate-based authentication, authentication methods policy after the retirement of the legacy MFA and SSPR settings, number matching enforced by default, PIM with authentication context, KQL detections.
- README describes only content that exists; planned content moved to the roadmap.

### Fixed

- The folder `identity-baselines` had trailing spaces in its name, which broke links and checkouts on Windows.
- The README linked to folders that did not exist (`intune-automation`, `graph-api`, `zero-trust`, `accelerators`, `docs`, `labs`, `governance`) and to a wrong GitHub profile.

## [1.0.0] - 2025-12-12

- Initial Conditional Access and security control baselines (documentation only).
