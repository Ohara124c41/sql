-- Udiddit normalized schema (five tables)
-- Run in a clean database (after loading bad tables if needed for migration).

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) NOT NULL,
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_users_username UNIQUE (username)
);

CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    description VARCHAR(500),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_topics_name UNIQUE (name)
);

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
