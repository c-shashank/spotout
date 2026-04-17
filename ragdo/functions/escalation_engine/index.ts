/**
 * RAGDO — Escalation Engine
 * Supabase Edge Function: runs every 6 hours via pg_cron or external cron.
 *
 * Trigger rules:
 *   Tier 2 (Municipal): upvotes ≥ 100 OR age ≥ 7 days OR comment surge ≥ 50/24hr
 *   Tier 3 (State): upvotes ≥ 500 OR (at Tier 2 for ≥ 21 days)
 *   Tier 4 (Media/NGO): upvotes ≥ 1000 OR age ≥ 45 days
 *
 * On escalation: update tier, append to history, set priority_flag, send FCM push.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const fcmServerKey = Deno.env.get("FCM_SERVER_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

interface Issue {
  id: string;
  title: string;
  upvote_count: number;
  comment_count: number;
  escalation_tier: string;
  escalation_history: EscalationEntry[];
  is_resolved: boolean;
  created_at: string;
  created_by: string;
  ward_id: string;
}

interface EscalationEntry {
  tier: string;
  triggered_by: string;
  triggered_at: string;
  reason: string;
}

function daysBetween(dateStr: string, now: Date): number {
  return Math.floor((now.getTime() - new Date(dateStr).getTime()) / 86400000);
}

async function check24hrCommentSurge(issueId: string): Promise<boolean> {
  const since = new Date(Date.now() - 86400000).toISOString();
  const { count } = await supabase
    .from("comments")
    .select("id", { count: "exact", head: true })
    .eq("issue_id", issueId)
    .gte("created_at", since);
  return (count ?? 0) >= 50;
}

function evaluateTier(issue: Issue, commentSurge: boolean): string | null {
  const now = new Date();
  const daysSinceCreated = daysBetween(issue.created_at, now);

  const tier2Entry = issue.escalation_history.find((h) => h.tier === "municipal");
  const daysSinceTier2 = tier2Entry ? daysBetween(tier2Entry.triggered_at, now) : null;

  if (issue.escalation_tier === "ward") {
    if (issue.upvote_count >= 100 || daysSinceCreated >= 7 || commentSurge) {
      const reasons: string[] = [];
      if (issue.upvote_count >= 100) reasons.push("upvote_count >= 100");
      if (daysSinceCreated >= 7) reasons.push(`days_at_ward >= 7 (${daysSinceCreated} days)`);
      if (commentSurge) reasons.push("comment_surge_24hr");
      return "municipal:" + reasons.join(",");
    }
  }

  if (issue.escalation_tier === "municipal") {
    if (issue.upvote_count >= 500 || (daysSinceTier2 !== null && daysSinceTier2 >= 21)) {
      const reasons: string[] = [];
      if (issue.upvote_count >= 500) reasons.push("upvote_count >= 500");
      if (daysSinceTier2 !== null && daysSinceTier2 >= 21) reasons.push(`days_at_municipal >= 21 (${daysSinceTier2} days)`);
      return "state:" + reasons.join(",");
    }
  }

  if (issue.escalation_tier === "state") {
    if (issue.upvote_count >= 1000 || daysSinceCreated >= 45) {
      const reasons: string[] = [];
      if (issue.upvote_count >= 1000) reasons.push("upvote_count >= 1000");
      if (daysSinceCreated >= 45) reasons.push(`total_days >= 45 (${daysSinceCreated} days)`);
      return "media_ngo:" + reasons.join(",");
    }
  }

  return null;
}

async function escalateIssue(issue: Issue, tierWithReason: string): Promise<void> {
  const [newTier, ...reasonParts] = tierWithReason.split(":");
  const reason = reasonParts.join(":");
  const now = new Date().toISOString();

  const newEntry: EscalationEntry = {
    tier: newTier,
    triggered_by: "auto_escalation_engine",
    triggered_at: now,
    reason,
  };

  const updatedHistory = [...issue.escalation_history, newEntry];

  const { error } = await supabase
    .from("issues")
    .update({
      escalation_tier: newTier,
      priority_flag: true,
      escalation_history: updatedHistory,
      updated_at: now,
    })
    .eq("id", issue.id);

  if (error) {
    console.error(`Failed to escalate issue ${issue.id}:`, error);
    return;
  }

  console.log(`Escalated issue ${issue.id} ("${issue.title}") to ${newTier} — ${reason}`);

  // Generate public alert card for Tier 4
  if (newTier === "media_ngo") {
    await generatePublicAlert(issue, reason);
  }

  // Send FCM push notifications
  await sendEscalationPush(issue, newTier);
}

async function generatePublicAlert(issue: Issue, reason: string): Promise<void> {
  const alertData = {
    issue_id: issue.id,
    tier: "media_ngo",
    title: issue.title,
    reason,
    share_url: `https://ragdo.in/issues/${issue.id}`,
    generated_at: new Date().toISOString(),
  };

  await supabase.from("public_alerts").insert(alertData).catch(() => {
    // Table may not exist in dev — log and continue
    console.log("Public alert generated:", alertData);
  });
}

async function sendEscalationPush(issue: Issue, newTier: string): Promise<void> {
  // Get issue creator + all upvoters
  const { data: voters } = await supabase
    .from("votes")
    .select("user_id")
    .eq("issue_id", issue.id)
    .eq("vote_type", "up");

  const recipientIds = new Set<string>([issue.created_by]);
  for (const v of voters ?? []) recipientIds.add(v.user_id);

  // Also notify authority users for the new tier
  const tierToRole: Record<string, string> = {
    municipal: "municipal_authority",
    state: "state_authority",
    media_ngo: "media_ngo",
  };
  const authorityRole = tierToRole[newTier];
  if (authorityRole) {
    const { data: authorities } = await supabase
      .from("users")
      .select("id")
      .eq("role", authorityRole)
      .or(`jurisdiction_wards.cs.{"${issue.ward_id}"},jurisdiction_wards.eq.{}`);
    for (const a of authorities ?? []) recipientIds.add(a.id);
  }

  const tierLabels: Record<string, string> = {
    municipal: "Municipal Corporation",
    state: "State Government",
    media_ngo: "Media / NGO Alert",
  };

  // Fetch FCM tokens
  const ids = Array.from(recipientIds);
  const { data: tokenRows } = await supabase
    .from("users")
    .select("fcm_token")
    .in("id", ids)
    .not("fcm_token", "is", null);

  const tokens = (tokenRows ?? [])
    .map((r) => r.fcm_token as string)
    .filter(Boolean);

  if (tokens.length === 0) return;

  // Send via FCM HTTP v1 (batch)
  const payload = {
    notification: {
      title: "🔺 Issue Escalated!",
      body: `"${issue.title.substring(0, 50)}" escalated to ${tierLabels[newTier] ?? newTier}`,
    },
    data: {
      type: "escalation",
      issue_id: issue.id,
      tier: newTier,
    },
  };

  // Fan out (FCM legacy API — replace with HTTP v1 for production)
  try {
    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        Authorization: `key=${fcmServerKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        registration_ids: tokens,
        ...payload,
      }),
    });
    const result = await res.json();
    console.log("FCM result:", JSON.stringify(result));
  } catch (e) {
    console.error("FCM send failed:", e);
  }

  // Create notification records in DB
  const notifRows = ids.map((uid) => ({
    user_id: uid,
    type: "escalation",
    title: "Issue Escalated",
    body: `"${issue.title.substring(0, 60)}" has been escalated to ${tierLabels[newTier] ?? newTier}`,
    issue_id: issue.id,
  }));

  await supabase.from("notifications").insert(notifRows);
}

async function runEscalationJob(): Promise<void> {
  console.log("Starting escalation job at", new Date().toISOString());

  const { data: issues, error } = await supabase
    .from("issues")
    .select("*")
    .eq("is_resolved", false)
    .neq("status", "rejected");

  if (error || !issues) {
    console.error("Failed to fetch issues:", error);
    return;
  }

  console.log(`Checking ${issues.length} open issues...`);
  let escalatedCount = 0;

  for (const issue of issues as Issue[]) {
    const commentSurge = await check24hrCommentSurge(issue.id);
    const result = evaluateTier(issue, commentSurge);
    if (result) {
      await escalateIssue(issue, result);
      escalatedCount++;
    }
  }

  console.log(`Escalation job complete. Escalated ${escalatedCount} issues.`);
}

// ── HTTP handler (Supabase Edge Function entrypoint) ─────────────────────────

Deno.serve(async (req: Request) => {
  // Accept GET/POST — called by pg_cron via HTTP or external scheduler
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Optional: verify a secret header to prevent unauthorized calls
  const secret = Deno.env.get("ESCALATION_ENGINE_SECRET");
  if (secret) {
    const authHeader = req.headers.get("x-escalation-secret");
    if (authHeader !== secret) {
      return new Response("Unauthorized", { status: 401 });
    }
  }

  try {
    await runEscalationJob();
    return Response.json({ status: "ok", timestamp: new Date().toISOString() });
  } catch (e) {
    console.error("Escalation job failed:", e);
    return Response.json({ status: "error", message: String(e) }, { status: 500 });
  }
});
