# Conditional Access Baseline – Level 1 (Baseline Security)

This baseline provides a **secure-by-default foundation** for all Microsoft Entra ID tenants.  
It focuses on blocking legacy protocols, enforcing MFA for admins, and protecting core workloads without breaking user productivity.

---

## 🎯 Objectives

- Remove high-risk authentication methods  
- Protect administrators from common attack vectors  
- Apply MFA to sensitive workloads  
- Ensure a minimum level of identity hygiene  
- Keep user friction low while raising security significantly  

---

# 🧱 Included Policies (Level 1)

## 🔹 1. Block Legacy Authentication  
**Objective:** Disable all basic auth protocols that bypass MFA.  
**Applies to:** All users  
**Exclusions:** Service accounts (if absolutely necessary)  

**Recommended settings:**  
- Client Apps → Exclude legacy protocols  
- Grant → Block access  

---

## 🔹 2. Require MFA for Administrators  
**Objective:** Protect privileged roles from credential-based attacks.  
**Scope:** All built-in admin roles  

**Recommended controls:**  
- Require multifactor authentication  
- Require password change on risk detection  

---

## 🔹 3. Require MFA for High-Risk Sign-ins (if licensed)  
**Objective:** Stop compromised accounts early.  
**Scope:** All users  
**Action:** Block or require MFA depending on organization maturity  

---

## 🔹 4. Require MFA for Key Cloud Apps  
**Apps included:**  
- Exchange Online  
- SharePoint Online  
- Teams  
- Microsoft Admin centers  

---

## 🔹 5. Break-Glass Account Configuration  
**Goal:** Ensure emergency access under CA enforcement  
- Exclude from all CA policies  
- Strong password + password vault  
- Monitor for unexpected sign-ins  

---

# 📘 Deployment Guidance

1. Deploy policies in **Report-only** first  
2. Validate sign-in logs  
3. Pilot with IT/Admin groups  
4. Enforce after approval  

This level is appropriate for **all** tenants and should be implemented before rolling out Level 2.
