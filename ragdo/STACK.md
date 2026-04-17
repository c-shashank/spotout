# STACK.md — Jawab Do Backend Choice

## Decision: Supabase

### Evaluation Criteria & Scores

| Criteria | Supabase | Firebase |
|---|---|---|
| Realtime feed updates | ✅ Postgres LISTEN/NOTIFY + Realtime channels | ✅ Firestore onSnapshot |
| Geospatial queries | ✅ **PostGIS** — native ST_DWithin for 2km "Near Me" filter | ⚠️ Geohash workaround required |
| File/media storage | ✅ Built-in S3-compatible Storage | ✅ Cloud Storage |
| Free tier viability | ✅ 500MB DB, 1GB storage, 2GB bandwidth, unlimited API | ⚠️ Spark plan has stricter limits |
| Flutter/Dart SDK | ✅ Official `supabase_flutter` v2, maintained by Supabase | ✅ Multiple Firebase Flutter plugins |
| Complex queries | ✅ **SQL** — escalation engine uses CTEs and aggregations trivially | ⚠️ NoSQL requires denormalization |
| Row-Level Security | ✅ Postgres RLS — enforced server-side | ⚠️ Firestore rules — separate DSL |
| Escalation engine host | ✅ **Edge Functions** (Deno) — co-located with DB, same env vars | ✅ Cloud Functions (Node.js) |

### Why Supabase Wins for Jawab Do

1. **PostGIS is essential.** The "Near Me" feed filter requires efficient geospatial proximity queries. PostGIS `ST_DWithin` handles this natively in a single query. Firebase would need Geohash bounding-box math, multiple queries, and client-side filtering — significantly more complexity.

2. **SQL for the escalation engine.** The 6-hour escalation job needs to:
   - Query all unresolved issues
   - Check comment counts in rolling 24hr windows
   - Compute days since tier changes from JSONB history

   All of this is trivial SQL/JSONB. In Firestore, this would require Cloud Functions with multiple reads or a separate time-series store.

3. **RLS with Postgres.** Authority access controls (internal notes, restricted views) map cleanly to Postgres RLS policies. The authority dashboard's need to show "internal" vs "public" actions is a single `WHERE is_internal = FALSE` clause.

4. **Free tier is generous.** Supabase's free tier provides 500MB Postgres, 1GB Storage, and 2GB bandwidth — sufficient to launch the MVP with 1000+ issues. Firebase Spark plan restricts Cloud Functions entirely.

5. **Single SDK.** `supabase_flutter` provides Auth, Database, Storage, Realtime, and Edge Functions in one package. We still use Firebase Auth for phone OTP (the spec mandates it) and Firebase Messaging for FCM.

### Architecture

```
Flutter App
    │
    ├── Firebase Auth      → Phone OTP (citizens) + Email (authority)
    ├── Firebase Messaging → FCM push notifications
    │
    └── Supabase
        ├── Database (Postgres + PostGIS)  → Issues, Users, Comments, Votes, etc.
        ├── Storage                         → Issue photos, Avatars, Authority proof
        ├── Realtime                        → Live upvote/comment count updates
        └── Edge Functions (Deno)          → Escalation engine (every 6hr)
```

### Trade-offs Accepted

- **Dual SDK overhead:** Using both Firebase (Auth + FCM) and Supabase adds ~5MB to APK size and two initialization calls. Acceptable given the spec mandates Firebase Auth for phone OTP.
- **Edge Function cold start:** Supabase Edge Functions have ~50-100ms cold starts. The escalation engine runs on a schedule (not user-facing), so this is irrelevant.
- **Realtime at scale:** Supabase Realtime uses WebSocket per-subscription. For a feed with 1000+ concurrent users, this works fine up to ~500 concurrent connections on the free tier. Beyond that, Realtime should be replaced with polling + cache.
