# Udiddit, a social news aggregator

## Introduction (from template)
Udiddit, a social news aggregation, web content rating, and discussion website, is currently using a risky and unreliable Postgres database schema to store the forum posts, discussions, and votes made by their users about different topics.

The schema allows posts to be created by registered users on certain topics, and can include a URL or a text content. It also allows registered users to cast an upvote (like) or downvote (dislike) for any forum post that has been created. In addition to this, the schema also allows registered users to add comments on posts.

Here is the DDL used to create the schema:

```sql
CREATE TABLE bad_posts (
	id SERIAL PRIMARY KEY,
	topic VARCHAR(50),
	username VARCHAR(50),
	title VARCHAR(150),
	url VARCHAR(4000) DEFAULT NULL,
	text_content TEXT DEFAULT NULL,
	upvotes TEXT,
	downvotes TEXT
);

CREATE TABLE bad_comments (
	id SERIAL PRIMARY KEY,
	username VARCHAR(50),
	post_id BIGINT,
	text_content TEXT
);
```

---

## Part I: Investigate the existing schema
As a first step, investigate this schema and some of the sample data in the project’s SQL workspace. Then, in your own words, outline three (3) specific things that could be improved about this schema. Don’t hesitate to outline more if you want to stand out!

### Findings and recommendations
- **User, topic, and vote denormalization**: Usernames and topic names are stored as free text in multiple places, which permits typos, duplication, and broken references. Add `users` and `topics` tables with FK references; enforce `UNIQUE` constraints on usernames and topic names with length limits.
- **Votes as comma-separated text**: `upvotes`/`downvotes` are comma-delimited strings, making it impossible to enforce one-vote-per-user, to index efficiently, or to cascade deletes. Create a `votes` table with `value` `CHECK (value IN (-1,1))`, `UNIQUE (user_id, post_id)`, and `ON DELETE CASCADE` on `post_id`.
- **Missing relational integrity for comments**: `bad_comments.post_id` lacks a foreign key; comment threads are only single-level. Add `comments` with FK to `posts` (`ON DELETE CASCADE`) and self-FK (`parent_comment_id`) with `ON DELETE CASCADE` to delete descendants.
- **No constraints on content fields**: Titles can exceed desired length, empty usernames/topics are allowed, and posts can contain both `url` and `text_content` (or neither). Use `NOT NULL` and `CHECK` constraints: title length ≤ 100, username length ≤ 25, topic length ≤ 30, and a post body exclusivity check `(url IS NULL) <> (text_content IS NULL)`.
- **Performance/indexing gaps**: Free-text fields prevent fast lookups for queries like “latest posts by topic/user,” “find by URL,” or “latest comments by user.” Add indexes: `(topic_id, created_at DESC)`, `(user_id, created_at DESC)` on posts/comments, and `(post_id)` on votes for scoring.

---

## Part II: Create the DDL for your new schema
Having done this initial investigation and assessment, your next goal is to dive deep into the heart of the problem and create a new schema for Udiddit. Your new schema should at least reflect fixes to the shortcomings you pointed to in the previous exercise.

Guideline #1 (feature requirements):
- Unique, non-empty usernames (≤ 25 chars); we ignore passwords.
- Unique, non-empty topic names (≤ 30 chars) with optional description (≤ 500 chars).
- Posts: required title (≤ 100 chars); either URL **or** text (not both); delete posts when topic is deleted; keep posts but clear owner when user is deleted.
- Comments: non-empty text; threaded via parent IDs; cascade delete with posts and with ancestor comments; keep comments but clear owner when user is deleted.
- Votes: single vote per user per post; keep votes but clear owner when user is deleted; delete votes when post is deleted.

Guideline #2 (queries to support): list inactive users by last login, users without posts, lookup by username/topic name, topics without posts, latest posts by topic/user, posts by URL, top-level/child comments, latest comments by user, and post score (upvotes - downvotes).

Guideline #3: use normalization, named constraints, and indexes.

Guideline #4: exactly five tables with auto-incrementing primary keys.

### DDL (run in this order)
```sql
-- 1) Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) NOT NULL,
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_users_username UNIQUE (username)
);

-- 2) Topics
CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    description VARCHAR(500),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_topics_name UNIQUE (name)
);

-- 3) Posts
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    topic_id INTEGER NOT NULL,
    user_id INTEGER,
    title VARCHAR(100) NOT NULL,
    url TEXT,
    text_content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_posts_topic FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
    CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT ck_posts_body_exclusive CHECK (
        (url IS NOT NULL AND text_content IS NULL)
        OR (url IS NULL AND text_content IS NOT NULL)
    )
);
CREATE INDEX idx_posts_topic_created_at ON posts (topic_id, created_at DESC);
CREATE INDEX idx_posts_user_created_at ON posts (user_id, created_at DESC);
CREATE INDEX idx_posts_url ON posts (url);

-- 4) Comments
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER,
    parent_comment_id INTEGER,
    text_content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_comments_parent FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE
);
CREATE INDEX idx_comments_post_parent ON comments (post_id, parent_comment_id);
CREATE INDEX idx_comments_user_created_at ON comments (user_id, created_at DESC);

-- 5) Votes
CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER,
    value SMALLINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_votes_value CHECK (value IN (-1, 1)),
    CONSTRAINT fk_votes_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_votes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT uq_votes_user_post UNIQUE (user_id, post_id)
);
CREATE INDEX idx_votes_post ON votes (post_id);
CREATE INDEX idx_votes_user ON votes (user_id);
```

---

## Part III: Migrate the provided data
Now that your new schema is created, it’s time to migrate the data from the provided schema in the project’s SQL Workspace to your own schema. This will allow you to review some DML and DQL concepts, as you’ll be using INSERT...SELECT queries to do so.

Guidelines and assumptions for migration:
- Topic descriptions can be empty.
- All migrated comments are top-level (`parent_comment_id` is `NULL`).
- Use `regexp_split_to_table` to unwind vote lists.
- Some users only vote or comment; create them too.
- Migration order matters: users → topics → posts → comments → votes.
- Long titles are truncated to 100 characters to satisfy the new limit.

### Data migration DML (run after creating the new schema)
```sql
-- 0) Optional: clean slate if re-running
TRUNCATE votes, comments, posts, topics, users RESTART IDENTITY;

-- 1) Users (gather from posts, comments, and vote strings)
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

-- 3) Posts (preserve original IDs for easy linkage)
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

-- 4) Comments (all top-level)
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

-- 5) Votes (unwind comma-separated lists, deduplicate)
WITH raw_votes AS (
    SELECT
        bp.id AS post_id,
        btrim(regexp_split_to_table(bp.upvotes, ',')) AS username,
        1 AS value
    FROM bad_posts bp
    WHERE bp.upvotes IS NOT NULL
    UNION ALL
    SELECT
        bp.id AS post_id,
        btrim(regexp_split_to_table(bp.downvotes, ',')) AS username,
        -1 AS value
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
```

### Optional DQL snippets (for validation and rubric “stand out”)
```sql
-- Latest 20 posts for a topic
SELECT p.*
FROM posts p
JOIN topics t ON t.id = p.topic_id
WHERE t.name = $1
ORDER BY p.created_at DESC
LIMIT 20;

-- Latest 20 posts by a user
SELECT p.*
FROM posts p
JOIN users u ON u.id = p.user_id
WHERE u.username = $1
ORDER BY p.created_at DESC
LIMIT 20;

-- Topics without posts
SELECT t.*
FROM topics t
LEFT JOIN posts p ON p.topic_id = t.id
WHERE p.id IS NULL;

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

-- Latest 20 comments by a user
SELECT c.*
FROM comments c
JOIN users u ON u.id = c.user_id
WHERE u.username = $1
ORDER BY c.created_at DESC
LIMIT 20;

-- Post score
SELECT p.id, COALESCE(SUM(v.value), 0) AS score
FROM posts p
LEFT JOIN votes v ON v.post_id = p.id
WHERE p.id = $1
GROUP BY p.id;

-- JSON with three-level nested comments for a post
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
```

---

## Rubric (for reference)
- SQL code is syntax highlighted, multi-lined, and indented for readability.
- Analysis notes at least three modeling flaws and pairs each with a recommendation.
- DDL executes without errors; schema satisfies all feature/query requirements, is normalized, consistent (FKs), and performant (no duplicate indexes).
- New schema enforces: unique non-empty usernames (≤ 25 chars); unique non-empty topics (≤ 30 chars, optional description ≤ 500); posts with required title ≤ 100 chars and exactly one of URL/text, cascade delete on topics, user deletion dissociates posts; threaded comments with non-empty text, cascades on post/ancestor delete, user deletion dissociates; one vote per user/post, cascade on post delete, user deletion dissociates.
- DML migrates all data correctly and runs without errors; order respects dependencies and preserves proper IDs; votes are deduplicated.
- For extra credit: more than three issues identified, clean naming, and challenging DQL (e.g., JSON nested comments).
