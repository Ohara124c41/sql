-- Data migration from bad_posts/bad_comments into normalized schema.
-- Assumes schema.sql already applied in the same database and bad tables are present.
-- If re-running, uncomment the TRUNCATE below.

-- TRUNCATE votes, comments, posts, topics, users RESTART IDENTITY;

-- 1) Users (collect from posts, comments, and vote lists)
WITH all_usernames AS (
    SELECT username FROM bad_posts
    UNION
    SELECT username FROM bad_comments
    UNION
    SELECT btrim(regexp_split_to_table(upvotes, ',')) FROM bad_posts WHERE upvotes IS NOT NULL
    UNION
    SELECT btrim(regexp_split_to_table(downvotes, ',')) FROM bad_posts WHERE downvotes IS NOT NULL
)
INSERT INTO users (username, last_login_at)
SELECT DISTINCT username, NOW()
FROM all_usernames
WHERE username IS NOT NULL AND btrim(username) <> '';

-- 2) Topics
INSERT INTO topics (name, description)
SELECT DISTINCT topic AS name, '' AS description
FROM bad_posts
WHERE topic IS NOT NULL AND btrim(topic) <> '';

-- 3) Posts (reuse IDs; enforce length/exclusivity)
INSERT INTO posts (id, topic_id, user_id, title, url, text_content, created_at)
SELECT
    bp.id,
    t.id AS topic_id,
    u.id AS user_id,
    LEFT(COALESCE(NULLIF(bp.title, ''), '(untitled)'), 100) AS title,
    CASE WHEN bp.url IS NOT NULL AND btrim(bp.url) <> '' THEN bp.url END AS url,
    CASE
        WHEN bp.url IS NOT NULL AND btrim(bp.url) <> '' THEN NULL
        ELSE COALESCE(NULLIF(bp.text_content, ''), 'No content provided')
    END AS text_content,
    NOW()
FROM bad_posts bp
JOIN topics t ON t.name = bp.topic
JOIN users u ON u.username = bp.username;
SELECT setval('posts_id_seq', (SELECT MAX(id) FROM posts));

-- 4) Comments (top-level only)
INSERT INTO comments (id, post_id, user_id, parent_comment_id, text_content, created_at)
SELECT
    bc.id,
    p.id AS post_id,
    u.id AS user_id,
    NULL AS parent_comment_id,
    bc.text_content,
    NOW()
FROM bad_comments bc
JOIN posts p ON p.id = bc.post_id
JOIN users u ON u.username = bc.username;
SELECT setval('comments_id_seq', (SELECT MAX(id) FROM comments));

-- 5) Votes (unwind and dedupe)
WITH raw_votes AS (
    SELECT bp.id AS post_id, btrim(regexp_split_to_table(bp.upvotes, ',')) AS username, 1 AS value
    FROM bad_posts bp
    WHERE bp.upvotes IS NOT NULL
    UNION ALL
    SELECT bp.id AS post_id, btrim(regexp_split_to_table(bp.downvotes, ',')) AS username, -1 AS value
    FROM bad_posts bp
    WHERE bp.downvotes IS NOT NULL
),
deduped AS (
    SELECT DISTINCT post_id, username, value
    FROM raw_votes
    WHERE username IS NOT NULL AND username <> ''
)
INSERT INTO votes (post_id, user_id, value, created_at)
SELECT
    d.post_id,
    u.id AS user_id,
    d.value,
    NOW()
FROM deduped d
JOIN users u ON u.username = d.username
JOIN posts p ON p.id = d.post_id;
SELECT setval('votes_id_seq', (SELECT MAX(id) FROM votes));
