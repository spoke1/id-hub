# Identity Baselines

This section contains opinionated, production-focused **identity security baselines** for Microsoft Entra ID.

The goal is to provide a **clear, staged path** from weak or legacy configurations towards a secure, Zero Trust–aligned identity posture.

---

## 🎯 Objectives

These baselines are designed to:

- Protect identities with **modern, phishing-resistant authentication** where possible  
- Enforce **strong Conditional Access** without breaking business-critical scenarios  
- Introduce **identity governance** in manageable steps  
- Provide **ready-to-communicate patterns** for architects, security teams and stakeholders  

---

## 🧱 Baseline Levels

Baselines are structured into three maturity levels:

| Level      | Description                                                                 | Typical Target |
|-----------|-----------------------------------------------------------------------------|----------------|
| **Level 1 – Baseline**   | Secure-by-default controls, legacy blockers, minimal friction                   | All tenants, starting point |
| **Level 2 – Enhanced**   | Strong MFA, stricter admin controls, improved device and session posture        | Organizations ready for stronger enforcement |
| **Level 3 – Enterprise** | Full Zero Trust alignment, risk-based access, strong governance & monitoring    | Mature or high-risk environments |

Each level builds on the previous one – **you don’t skip levels**, you grow into them.

---

## 📂 Folder Structure

```text
identity-baselines/
  ├── conditional-access/      → CA policy packs & documentation
  ├── governance/              → Identity Governance baselines (EM, Reviews, lifecycle)
  └── security-controls/       → Additional identity security controls & patterns
