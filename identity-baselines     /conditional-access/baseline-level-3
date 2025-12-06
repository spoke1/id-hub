# Conditional Access Baseline – Level 3 (Enterprise / Zero Trust)

Level 3 represents a **fully mature Zero Trust identity posture**, integrating risk, device posture, session controls, and continuous evaluation.

This level is designed for regulated industries, high-security environments, or organizations committed to Zero Trust Architecture.

---

## 🎯 Objectives

- Enforce identity security at every access decision  
- Combine signals: identity, device, session, risk  
- Minimize lateral movement and session hijacking  
- Protect privileged roles with maximum restrictions  
- Achieve full Zero Trust alignment across identity & endpoints  

---

# 🧱 Included Policies (Level 3)

## 🔹 1. Admin Access – Strict Controls  
Grant access only if:  
- Hybrid or compliant device  
- Modern Auth client  
- MFA enforced  
- Location-aware signals validated  
- Sign-in frequency ≤ 12 hours  

---

## 🔹 2. Sensitive Apps Require Compliant Devices Only  
Examples:  
- CRM  
- ERP  
- Finance  
- Trade systems  
- Healthcare or regulated workloads  

No unmanaged devices allowed.

---

## 🔹 3. Block High-Risk and Medium-Risk Sign-ins  
With Identity Protection:  
- High-risk → Block  
- Medium-risk → Require secure password reset + MFA reauth  

---

## 🔹 4. Require Passwordless Authentication for Admin Roles  
Allowed methods:  
- FIDO2 Security Keys  
- Windows Hello for Business  
- Microsoft Authenticator (number matching mandatory)  

---

## 🔹 5. Strict Session Controls  
- Disable persistent sessions globally  
- Sign-in frequency adjusted to risk (8–12h)  
- Conditional session lifetime (high sensitivity apps only)  

---

## 🔹 6. Complete Monitoring Integration  
- SIEM ingestion (Entra logs + CA logs + Risk events)  
- UEBA monitoring  
- Alerts for policy failures  

---

# 📘 Deployment Guidance

Deploy in phases:

1. Admin accounts  
2. Executive / sensitive roles  
3. Sensitive applications  
4. Full organizational rollout  

Level 3 requires **device maturity + MFA maturity** to succeed.
