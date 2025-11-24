-- Helper queries for rubric checks and manual validation.

-- Users with no posts
SELECT u.id, u.username
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
WHERE p.id IS NULL;

-- Topics without posts
SELECT t.id, t.name
FROM topics t
LEFT JOIN posts p ON p.topic_id = t.id
WHERE p.id IS NULL;

-- Latest 20 posts for a topic name
SELECT p.*
FROM posts p
JOIN topics t ON t.id = p.topic_id
WHERE t.name = $1
ORDER BY p.created_at DESC
LIMIT 20;

-- Latest 20 posts by username
SELECT p.*
FROM posts p
JOIN users u ON u.id = p.user_id
WHERE u.username = $1
ORDER BY p.created_at DESC
LIMIT 20;

-- Posts by URL (for moderation)
SELECT p.*
FROM posts p
WHERE p.url = $1;

-- Top-level comments for a post
SELECT c.*
FROM comments c
WHERE c.post_id = $1 AND c.parent_comment_id IS NULL
ORDER BY c.created_at;

-- Direct children of a comment
SELECT c.*
FROM comments c
WHERE c.parent_comment_id = $1
ORDER BY c.created_at;

-- Latest 20 comments by username
SELECT c.*
FROM comments c
JOIN users u ON u.id = c.user_id
WHERE u.username = $1
ORDER BY c.created_at DESC
LIMIT 20;

-- Post score (upvotes - downvotes)
SELECT p.id, COALESCE(SUM(v.value), 0) AS score
FROM posts p
LEFT JOIN votes v ON v.post_id = p.id
WHERE p.id = $1
GROUP BY p.id;

-- JSON aggregation of comments up to three levels for a post
WITH RECURSIVE threaded AS (
    SELECT c.id, c.post_id, c.parent_comment_id, c.text_content, c.created_at, 1 AS depth
    FROM comments c
    WHERE c.post_id = $1 AND c.parent_comment_id IS NULL
    UNION ALL
    SELECT c.id, c.post_id, c.parent_comment_id, c.text_content, c.created_at, t.depth + 1
    FROM comments c
    JOIN threaded t ON c.parent_comment_id = t.id
    WHERE t.depth < 3
)
SELECT json_agg(root)
FROM (
    SELECT
        t.id,
        t.text_content,
        t.created_at,
        (
            SELECT json_agg(child)
            FROM (
                SELECT
                    t2.id,
                    t2.text_content,
                    t2.created_at,
                    (
                        SELECT json_agg(grandchild)
                        FROM (
                            SELECT t3.id, t3.text_content, t3.created_at
                            FROM threaded t3
                            WHERE t3.parent_comment_id = t2.id
                            ORDER BY t3.created_at
                        ) grandchild
                    ) AS children
                FROM threaded t2
                WHERE t2.parent_comment_id = t.id
                ORDER BY t2.created_at
            ) child
        ) AS children
    FROM threaded t
    WHERE t.parent_comment_id IS NULL
    ORDER BY t.created_at
) root;
