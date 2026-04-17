# AUTHORITY_ROLES.md — Jawab Do Authority System

## Role Hierarchy

```
admin
  └── state_authority
        └── municipal_authority
              └── ward_authority
                    └── (citizen — no authority access)

media_ngo — separate track, Tier 4 alert recipients only
```

## Role Definitions

### `ward_authority`
- **Who:** GHMC Ward Engineers, Ward Level Officers
- **Jurisdiction:** 1–5 specific wards (set in `jurisdiction_wards[]`)
- **Can see:** All issues in their jurisdiction wards
- **Can do:**
  - Acknowledge issues
  - Mark In Progress / Resolved / Rejected
  - Add internal notes (hidden from citizens)
  - Assign issue to a department (GHMC/HMWSSB/TSSPDCL/TSRTC/Revenue)
  - Manually escalate to next tier with reason
  - View authority stats dashboard for their wards
- **Cannot see:** Issues outside their jurisdiction (filtered by `ward_id`)
- **Login:** Email + Password (Firebase Auth)

### `municipal_authority`
- **Who:** GHMC Zone-level Officers, Senior Commissioners
- **Jurisdiction:** All wards (empty `jurisdiction_wards` = all wards)
- **Can see:** All escalated-to-municipal issues, all ward issues
- **Can do:** Everything ward_authority can + see all wards
- **Login:** Email + Password

### `state_authority`
- **Who:** Telangana State Government Officials
- **Jurisdiction:** All wards
- **Can see:** All escalated-to-state issues
- **Can do:** Everything municipal_authority can
- **Login:** Email + Password

### `media_ngo`
- **Who:** Registered Media Outlets, NGOs
- **Can see:** Only public Tier 4 alert objects + public issue data
- **Can do:** Read-only — no action taking
- **Login:** Email + Password (pre-created by admin)

### `admin`
- **Who:** Jawab Do platform administrators
- **Can do:** Create authority accounts, assign jurisdictions, all CRUD
- **Login:** Email + Password

## How Admin Creates Authority Accounts

Authority accounts are **never self-registered**. The process:

1. Admin logs into the Supabase Dashboard or admin panel
2. Creates Firebase Auth user with email + password:
   ```bash
   firebase auth:create-user --email officer@ghmc.gov.in --password <temp_password>
   ```
   Or use Firebase Admin SDK:
   ```typescript
   const user = await admin.auth().createUser({
     email: 'officer@ghmc.gov.in',
     password: 'TempPassword123!',
     displayName: 'GHMC Ward Engineer - Bowenpally',
   });
   ```
3. Creates corresponding Supabase `users` record with the Firebase UID:
   ```sql
   INSERT INTO users (id, email, name, role, department, ward_id, jurisdiction_wards)
   VALUES (
     '<firebase_uid>',
     'officer@ghmc.gov.in',
     'GHMC Ward Engineer - Bowenpally',
     'ward_authority',
     'GHMC',
     'W075',
     ARRAY['W075', 'W076', 'W077']
   );
   ```
4. Admin sends credentials to the official securely
5. Official logs in via the Authority Portal (email + password screen)

## App Launch Role Routing

On app launch, the auth state listener checks:
```dart
if (user.role == UserRole.citizen) → CitizenShell (bottom nav)
if (user.isAuthority)             → AuthorityShell (side drawer)
```

If an email/password login attempts to access the authority portal but the `users` record has `role = 'citizen'`, login is blocked with the error: **"This account does not have authority access."**

## Jurisdiction Filtering

The `jurisdiction_wards` field is an array of ward codes:
- `['W075', 'W076', 'W077']` — specific wards
- `[]` (empty) — all wards (used for municipal/state authority)

The authority dashboard always filters the issue queue by `ward_id IN jurisdiction_wards` (or all wards if empty).

## Department Assignment

When a ward authority assigns an issue to a department:

| Department | Responsible For |
|---|---|
| GHMC | Roads, Garbage, Encroachments |
| HMWSSB | Water & Drainage |
| TSSPDCL | Electricity & Streetlights |
| TSRTC | Traffic & Signals (coordination) |
| Revenue Dept | Encroachments on government land |

The assignment sends an FCM notification to the relevant authority user in the target department for the issue's ward.
