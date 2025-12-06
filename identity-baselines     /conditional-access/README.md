# Conditional Access Baselines  
### Staged security policies for Microsoft Entra ID

This folder contains **staged Conditional Access (CA) baselines** that help you move from minimal identity protection to a fully mature Zero Trust posture.

The baselines are designed to be **practical**, **deployable**, and **aligned with Microsoft best practices**, while still flexible enough to adapt to any organization.

---

## 🎯 Purpose

Conditional Access is the core enforcement engine of identity security.  
These baselines provide:

- A clear, incremental adoption path  
- Ready-to-deploy policy sets  
- Minimal friction for Level 1  
- Strong protections for Level 2  
- Zero Trust alignment for Level 3  
- Documentation useful for architects, engineers & security teams  

---

## 🧱 Baseline Levels

Each baseline file contains **complete policy definitions**, recommended settings, and rollout guidance.

| Baseline Level | Description | File |
|----------------|-------------|------|
| **Level 1 – Baseline Security** | Secure-by-default foundation; blocks legacy auth; MFA for admins; minimal disruption | [`baseline-level-1.md`](baseline-level-1.md) |
| **Level 2 – Enhanced Security** | Broad MFA enforcement; device compliance for sensitive apps; hardened admin access | [`baseline-level-2.md`](baseline-level-2.md) |
| **Level 3 – Enterprise / Zero Trust** | Strict, risk-based, device-aware access policies; passwordless for admins; tight session control | [`baseline-level-3.md`](baseline-level-3.md) |

---

## 📊 Policy Comparison Matrix

A full cross-level comparison is available here:

➡️ **[`policy-matrix.md`](policy-matrix.md)**

This matrix is ideal for:

- Stakeholder communication  
- Architecture workshops  
- Roadmap planning  
- Security assessments  
- Zero Trust maturity scoring  

---

## 🧩 Folder Structure

```text
conditional-access/
  ├── README.md               ← You are here
  ├── baseline-level-1.md     ← Level 1 baseline policies
  ├── baseline-level-2.md     ← Level 2 baseline policies
  ├── baseline-level-3.md     ← Level 3 baseline policies
  └── policy-matrix.md        ← Cross-level comparison matrix
