# Conditional Access Policy Matrix  
### Comparison of Level 1, Level 2, and Level 3 Baselines

This matrix shows how each Conditional Access policy evolves across the three maturity levels.

---

## 🧱 Policy Overview Table

| Policy Theme | Level 1 – Baseline | Level 2 – Enhanced | Level 3 – Enterprise |
|--------------|-------------------|--------------------|----------------------|
| Block Legacy Authentication | ✔ Mandatory | ✔ Mandatory | ✔ Mandatory |
| MFA for Admins | ✔ Required | ✔ Required | ✔ Passwordless Required |
| MFA for End Users | Limited (key apps) | Broad MFA | Strong MFA + Risk Integration |
| Admin Access Restrictions | Minimal | Managed/Compliant device | Strict (hybrid/compliant only) |
| Device Compliance Requirement | Optional | Required for sensitive apps | Required for all key workloads |
| Session Controls | Minimal | Tuned for workload | Strict, short lifetime |
| High-Risk Sign-ins | MFA required | Block or reset | Block |
| Medium-Risk Sign-ins | Optional | Require MFA/reset | Require reset + MFA |
| Break-glass Accounts | Excluded | Monitored | Monitored + Audited |
| App Protection Policies | Optional | Recommended | Strongly recommended |
| Passwordless | Optional | Emerging use | Required for admins |
| Monitoring Integration | Not required | Recommended | Full SIEM/UEBA integration |

---

# 📘 How to Use the Matrix

- Use this table to **communicate maturity levels** to stakeholders  
- Helps identity teams plan a **roadmap from Level 1 → Level 3**  
- Useful as a **workshop tool** during Zero Trust assessments  
- Can be exported into PowerPoint, Excel or customer documentation  

---

## 🧩 Related Files

- `baseline-level-1.md`  
- `baseline-level-2.md`  
- `baseline-level-3.md`  

These documents contain the detailed policy definitions for each level.
