-- Allow initial citizen profile creation from the app before Supabase-auth session exists.
-- This is scoped to INSERT only and citizen defaults to reduce abuse surface.

CREATE POLICY "users_insert_citizen_profile_bootstrap"
ON users
FOR INSERT
TO anon, authenticated
WITH CHECK (
  role = 'citizen'
  AND name IS NOT NULL
  AND char_length(name) > 0
  AND char_length(name) <= 120
  AND karma_score = 0
  AND issues_filed_count = 0
  AND issues_resolved_count = 0
);
