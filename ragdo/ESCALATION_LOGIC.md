# ESCALATION_LOGIC.md — Jawab Do Issue Escalation System

## Overview

Every issue starts at **Tier 1 (Ward)**. An automated engine runs every 6 hours to check all open issues and promote them up the government hierarchy if escalation conditions are met.

## Escalation Tiers

| Tier | Level | Color | Who Handles |
|---|---|---|---|
| 1 — Ward | `ward` | Grey `#9E9E9E` | GHMC Ward Engineer / Commissioner |
| 2 — Municipal | `municipal` | Blue `#0077CC` | GHMC Municipal Corporation |
| 3 — State | `state` | Orange `#FF6F00` | Telangana State Government |
| 4 — Media/NGO | `media_ngo` | Red `#CC0000` (pulsing) | Media outlets + NGOs |

## Trigger Rules

### Tier 1 → Tier 2 (Municipal)
Triggered if **ANY** of:
- `upvote_count ≥ 100`
- Issue is `7+ days old` AND still unresolved
- `comment_count grew by ≥ 50` within any rolling 24-hour window

### Tier 2 → Tier 3 (State)
Triggered if **ANY** of (AND currently at Tier 2):
- `upvote_count ≥ 500`
- `21+ days have passed` since reaching Tier 2 AND still unresolved

### Tier 3 → Tier 4 (Media/NGO Alert)
Triggered if **ANY** of (AND currently at Tier 3):
- `upvote_count ≥ 1,000`
- `45+ days` since `created_at` AND still unresolved

## Escalation History

Each escalation event appends an entry to `issues.escalation_history` (JSONB array):

```json
{
  "tier": "municipal",
  "triggered_by": "auto_escalation_engine",
  "triggered_at": "2026-03-23T12:00:00Z",
  "reason": "upvote_count >= 100"
}
```

For manual escalations by authority officials:

```json
{
  "tier": "state",
  "triggered_by": "auth_user_id_here",
  "triggered_at": "2026-03-23T14:00:00Z",
  "reason": "Beyond ward jurisdiction"
}
```

## Comment Surge Detection

The 24-hour comment surge check queries the `comments` table directly:

```sql
SELECT COUNT(*) FROM comments
WHERE issue_id = $1
  AND created_at >= NOW() - INTERVAL '24 hours';
```

If this count ≥ 50, the surge trigger fires for Ward → Municipal escalation.

## Engine Schedule

The escalation engine is deployed as a **Supabase Edge Function** at:
`/functions/v1/escalation-engine`

It is scheduled every 6 hours using **pg_cron** (Supabase built-in):

```sql
SELECT cron.schedule(
  'escalation-engine-6hr',
  '0 */6 * * *',
  $$
  SELECT net.http_post(
    url := 'https://<project>.supabase.co/functions/v1/escalation-engine',
    headers := '{"x-escalation-secret": "<SECRET>"}',
    body := '{}'
  );
  $$
);
```

Or via an external cron service (e.g. GitHub Actions, Fly.io cron) calling the HTTP endpoint.

## Tier 4 Alert Object

When an issue reaches Tier 4, a public alert object is generated and stored:

```json
{
  "issue_id": "uuid",
  "tier": "media_ngo",
  "title": "Issue title",
  "reason": "upvote_count >= 1000",
  "share_url": "https://jawabdo.in/issues/uuid",
  "generated_at": "2026-03-23T18:00:00Z"
}
```

This is stored in a `public_alerts` table and the deep link is shareable.

## Side Effects on Escalation

On any escalation event, the engine:
1. Updates `issues.escalation_tier` to the new tier
2. Appends to `issues.escalation_history`
3. Sets `issues.priority_flag = true` (all Tier 2+ issues are priority)
4. Sends FCM push to:
   - Issue creator
   - All users who upvoted the issue
   - Authority users for the new tier (filtered by ward)
5. Creates `notifications` records in the DB

## Manual Escalation (Authority)

Authority officials can escalate an issue manually from the Authority Issue Detail screen. They must provide a reason from:
- Beyond ward jurisdiction
- Resource constraint
- Policy issue
- Requires state funding
- Other

Manual escalations create an `authority_actions` record with `action_type = 'escalated'` and append to `escalation_history` with `triggered_by = authority_user_id`.
