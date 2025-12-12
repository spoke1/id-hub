# Identity Security Controls  
### Technical security foundations beyond Conditional Access

This section defines **identity-related security controls** that complement Conditional Access and Governance.

While Conditional Access enforces *access decisions*, these controls ensure that:
- identities are protected,
- privileged access is controlled,
- risks are detected early,
- and emergency access is handled safely.

---

## 🎯 Purpose

Identity Security Controls focus on:

- Identity Protection & risk signals  
- Privileged Identity Management (PIM)  
- Break-glass strategies  
- Authentication hygiene (MFA / passwordless)  
- Monitoring, logging & alerting  

They provide the **technical backbone** of a Zero Trust identity architecture.

---

## 🧱 Security Levels

| Level | Description | File |
|------|-------------|------|
| **Level 1 – Foundational Security** | Basic protection, visibility & emergency access | [`security-level-1.md`](security-level-1.md) |
| **Level 2 – Hardened Security** | Strong privileged access controls & identity protection | [`security-level-2.md`](security-level-2.md) |
| **Level 3 – Zero Trust Security** | Continuous evaluation, passwordless-first, SIEM-driven | [`security-level-3.md`](security-level-3.md) |

---

## 🧩 Scope of This Section

Included topics:

- Identity Protection configuration  
- Privileged Identity Management (PIM)  
- Authentication method governance  
- Break-glass account patterns  
- Monitoring & alerting  

Not included here:
- Conditional Access policies (see `conditional-access/`)  
- Identity lifecycle governance (see `governance/`)  

---

## 🚀 How to Use

1. Implement **Level 1** immediately  
2. Align **Level 2** with Conditional Access Level 2  
3. Use **Level 3** for Zero Trust programs and regulated environments  

Each level builds on the previous one.
