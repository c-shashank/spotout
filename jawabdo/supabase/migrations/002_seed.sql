-- ╔══════════════════════════════════════════════════════════════╗
-- ║                RAGDO — Seed Data (10 Issues)                 ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Seed citizen users
INSERT INTO users (id, phone, name, ward_id, role, karma_score, issues_filed_count, created_at)
VALUES
  ('seed_user_1', '+919876543210', 'Shekhar Reddy',       'W075', 'citizen', 145, 6, NOW() - INTERVAL '90 days'),
  ('seed_user_2', '+919876543211', 'Priya Sharma',        'W026', 'citizen', 340, 12, NOW() - INTERVAL '60 days'),
  ('seed_user_3', '+919876543212', 'Ravi Kumar',          'W041', 'citizen', 87,  3, NOW() - INTERVAL '30 days'),
  ('seed_user_4', '+919876543213', 'Anitha Lakshmi',      'W052', 'citizen', 520, 18, NOW() - INTERVAL '120 days'),
  ('seed_user_5', '+919876543214', 'Mohammed Aziz',       'W011', 'citizen', 62,  2, NOW() - INTERVAL '10 days'),
  -- Authority users (pre-created by admin)
  ('auth_user_1', NULL, 'GHMC Ward Engineer - Bowenpally', 'W075', 'ward_authority', 0, 0, NOW() - INTERVAL '180 days'),
  ('auth_user_2', NULL, 'GHMC Senior Officer',             NULL,   'municipal_authority', 0, 0, NOW() - INTERVAL '180 days')
ON CONFLICT (id) DO NOTHING;

-- Update authority user email for login
UPDATE users SET email = 'officer@ghmc.gov.in' WHERE id = 'auth_user_1';
UPDATE users SET department = 'GHMC', jurisdiction_wards = ARRAY['W075','W076','W077'] WHERE id = 'auth_user_1';
UPDATE users SET email = 'senior@ghmc.gov.in' WHERE id = 'auth_user_2';
UPDATE users SET department = 'GHMC' WHERE id = 'auth_user_2';

-- Seed 10 issues across Hyderabad wards
INSERT INTO issues (
  id, title, description, category, status,
  location_lat, location_lng, address_label, ward_id,
  media_urls, created_by, created_at, updated_at,
  upvote_count, downvote_count, comment_count,
  escalation_tier, escalation_history,
  is_resolved, priority_flag
) VALUES
(
  uuid_generate_v4(),
  'Large pothole on Bowenpally main road near SBI',
  'Deep pothole near State Bank of India branch has caused 3 accidents in the last month. Needs immediate repair.',
  'roads', 'in_progress',
  17.4674, 78.4952,
  'Near SBI, Bowenpally, Hyderabad',
  'W075',
  ARRAY['https://picsum.photos/seed/issue1/400/300'],
  'seed_user_1',
  NOW() - INTERVAL '12 days', NOW() - INTERVAL '2 days',
  234, 8, 47,
  'municipal',
  jsonb_build_array(jsonb_build_object('tier','municipal','triggered_by','auto_escalation_engine','triggered_at',NOW() - INTERVAL '5 days','reason','upvote_count >= 100')),
  FALSE, TRUE
),
(
  uuid_generate_v4(),
  'Overflowing drainage on Jubilee Hills Road No. 36',
  'Drainage has been overflowing since last monsoon. The road gets flooded every time it rains, making it impassable.',
  'water', 'open',
  17.4318, 78.4070,
  'Road No. 36, Jubilee Hills, Hyderabad',
  'W028',
  ARRAY['https://picsum.photos/seed/issue2/400/300'],
  'seed_user_2',
  NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days',
  156, 4, 23,
  'ward',
  '[]'::JSONB,
  FALSE, FALSE
),
(
  uuid_generate_v4(),
  'Garbage not collected for 5 days in Kukatpally Phase 7',
  'GHMC garbage collection truck has not visited our street for 5 days. Waste piling up causing health hazard.',
  'garbage', 'open',
  17.4948, 78.3996,
  'Phase 7, Kukatpally, Hyderabad',
  'W052',
  ARRAY['https://picsum.photos/seed/issue3/400/300'],
  'seed_user_3',
  NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days',
  89, 2, 12,
  'ward',
  '[]'::JSONB,
  FALSE, FALSE
),
(
  uuid_generate_v4(),
  'Streetlight not working near Paradise Circle for 3 weeks',
  '4 streetlights near Paradise Circle signal have been non-functional for 3 weeks creating safety hazard at night.',
  'electricity', 'open',
  17.4435, 78.4989,
  'Paradise Circle, Secunderabad',
  'W145',
  ARRAY['https://picsum.photos/seed/issue4/400/300'],
  'seed_user_4',
  NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days',
  567, 12, 89,
  'state',
  jsonb_build_array(jsonb_build_object('tier','municipal','triggered_by','auto_escalation_engine','triggered_at',NOW() - INTERVAL '14 days','reason','days_at_ward >= 7'),jsonb_build_object('tier','state','triggered_by','auto_escalation_engine','triggered_at',NOW() - INTERVAL '3 days','reason','upvote_count >= 500')),
  FALSE, TRUE
),
(
  uuid_generate_v4(),
  'Illegal construction blocking footpath in Banjara Hills',
  'Shop owner has constructed a permanent structure on the footpath in front of plot 8/3, Banjara Hills. Pedestrians forced to walk on road.',
  'encroachment', 'open',
  17.4145, 78.4486,
  'Road No. 12, Banjara Hills, Hyderabad',
  'W030',
  ARRAY['https://picsum.photos/seed/issue5/400/300'],
  'seed_user_5',
  NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days',
  45, 6, 8,
  'ward',
  '[]'::JSONB,
  FALSE, FALSE
),
(
  uuid_generate_v4(),
  'Signal malfunction at Panjagutta junction causing traffic chaos',
  'Traffic signal at Panjagutta roundabout is stuck on red for all directions during peak hours. Major congestion from 8AM-10AM.',
  'traffic', 'in_progress',
  17.4325, 78.4488,
  'Panjagutta Junction, Hyderabad',
  'W027',
  ARRAY['https://picsum.photos/seed/issue6/400/300'],
  'seed_user_1',
  NOW() - INTERVAL '4 days', NOW() - INTERVAL '1 day',
  312, 5, 56,
  'municipal',
  jsonb_build_array(jsonb_build_object('tier','municipal','triggered_by','auto_escalation_engine','triggered_at',NOW() - INTERVAL '2 days','reason','upvote_count >= 100')),
  FALSE, TRUE
),
(
  uuid_generate_v4(),
  'Water pipe burst flooding Marredpally main road',
  'HMWSSB water main has burst near Marredpally circle. Entire road flooded for 2 days. Water wastage is enormous.',
  'water', 'resolved',
  17.4489, 78.5019,
  'Marredpally Circle, Secunderabad',
  'W086',
  ARRAY['https://picsum.photos/seed/issue7/400/300'],
  'seed_user_2',
  NOW() - INTERVAL '15 days', NOW() - INTERVAL '3 days',
  423, 3, 67,
  'municipal',
  jsonb_build_array(jsonb_build_object('tier','municipal','triggered_by','auto_escalation_engine','triggered_at',NOW() - INTERVAL '8 days','reason','upvote_count >= 100')),
  TRUE, FALSE
),
(
  uuid_generate_v4(),
  'Dumping of construction waste on footpath near ECIL',
  'Construction company has been illegally dumping debris on the public footpath near ECIL main road for 2 weeks.',
  'encroachment', 'open',
  17.4713, 78.5577,
  'ECIL Main Road, Hyderabad',
  'W049',
  ARRAY['https://picsum.photos/seed/issue8/400/300'],
  'seed_user_3',
  NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days',
  67, 1, 4,
  'ward',
  '[]'::JSONB,
  FALSE, FALSE
),
(
  uuid_generate_v4(),
  'Pothole row on Gachibowli Outer Ring Road service lane',
  'Series of 6 potholes on the ORR service lane near DLF gate. Multiple vehicles damaged. 2-wheelers at serious risk.',
  'roads', 'open',
  17.4401, 78.3489,
  'ORR Service Lane, near DLF, Gachibowli',
  'W065',
  ARRAY['https://picsum.photos/seed/issue9/400/300'],
  'seed_user_4',
  NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days',
  178, 7, 34,
  'ward',
  '[]'::JSONB,
  FALSE, FALSE
),
(
  uuid_generate_v4(),
  'Transformer explosion risk in Uppal - sparking since morning',
  'Electrical transformer near Uppal crossroads has been sparking since 7AM. Dangerous for nearby residents and vehicles.',
  'electricity', 'open',
  17.4066, 78.5585,
  'Uppal Crossroads, Hyderabad',
  'W045',
  ARRAY['https://picsum.photos/seed/issue10/400/300'],
  'seed_user_5',
  NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day',
  892, 2, 145,
  'state',
  jsonb_build_array(jsonb_build_object('tier','municipal','triggered_by','auto_escalation_engine','triggered_at',NOW() - INTERVAL '18 hours','reason','comment_surge_24hr'),jsonb_build_object('tier','state','triggered_by','auto_escalation_engine','triggered_at',NOW() - INTERVAL '6 hours','reason','upvote_count >= 500')),
  FALSE, TRUE
);

-- Seed one authority action (response to issue 1)
INSERT INTO authority_actions (issue_id, authority_id, action_type, note, is_internal, created_at)
SELECT
  i.id,
  'auth_user_1',
  'in_progress',
  'Repair crew dispatched. Work scheduled for this Saturday.',
  FALSE,
  NOW() - INTERVAL '2 days'
FROM issues i
WHERE i.title LIKE '%Bowenpally main road%'
LIMIT 1;

-- Update issue 1 status
UPDATE issues SET status = 'in_progress' WHERE title LIKE '%Bowenpally main road%';
