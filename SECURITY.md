# Security policy

## Reporting a vulnerability

Please do not open a public issue for security problems. Use GitHub's private vulnerability reporting instead: **Security → Report a vulnerability** in this repository. You will get a response within a few working days.

## Scope

In scope are the templates, scripts and workflows in this repository, for example:

- a template that could lock out administrators or weakens a control it claims to enforce
- a script that changes more than documented (for example enables policies or modifies existing ones)
- secrets or tenant-specific identifiers committed to the repository

## Handling of secrets

This repository contains no secrets, tenant IDs or object IDs of any tenant, and it must stay that way:

- Templates contain only built-in identifiers (role template IDs, authentication strength IDs) and the placeholder `{{BREAK_GLASS_GROUP_ID}}`. A CI test rejects any other ID.
- Scripts authenticate with delegated sign-in or an existing app-only session with a certificate.
- Exports (`out/`) contain tenant data and are excluded via `.gitignore`.
- Every push and pull request is scanned with [gitleaks](https://github.com/gitleaks/gitleaks).
