# Udiddit: Social News Aggregator

This subproject redesigns the Udiddit database schema, migrates existing data from a denormalized “bad” schema, and provides helper queries for validation and reporting.

## Contents
- `instructions.md` — full project write-up (analysis, DDL, DML, rubric notes, optional DQL).
- `schema.sql` — normalized 5-table schema with named constraints and indexes.
- `migration.sql` — INSERT…SELECT migration from `bad_posts`/`bad_comments` into the new schema (includes title truncation to 100 chars and URL/text exclusivity).
- `validation_queries.sql` — helper queries for checks (inactive/no-post users, topics without posts, latest posts/comments, scores, JSON nested comments).
- `bad-db.sql` — source data and original bad schema.
- `docs/` — project PDF.

## Quick start (Docker + Postgres 15)
```sh
docker context use desktop-linux    # if on Docker Desktop for Windows/WSL
docker run --name udiddit-pg \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_USER=udiddit \
  -e POSTGRES_DB=udiddit \
  -p 55432:5432 -d postgres:15
```

Load bad data, create schema, migrate:
```sh
docker cp bad-db.sql udiddit-pg:/tmp/
docker exec -i udiddit-pg psql -U udiddit -d udiddit -f /tmp/bad-db.sql

docker cp schema.sql udiddit-pg:/tmp/
docker exec -i udiddit-pg psql -U udiddit -d udiddit -f /tmp/schema.sql

# If re-running migration, uncomment TRUNCATE in migration.sql first
docker cp migration.sql udiddit-pg:/tmp/
docker exec -i udiddit-pg psql -U udiddit -d udiddit -f /tmp/migration.sql
```

### Option: one-command bring-up with Docker Compose
The included `docker-compose.yml` mounts the SQL files into Postgres’ init directory; on first start it will load `bad-db.sql`, create the new schema, and run the migration automatically.
```sh
cd social_news_aggregator
docker compose up -d
# After first boot, data is already migrated. Recreate fresh by removing the volume:
# docker compose down -v && docker compose up -d
```

Expected counts after migration with provided data:
- users: 11077
- topics: 89
- posts: 50000
- comments: 100000
- votes: ~499710

Run validation helpers:
```sh
docker cp validation_queries.sql udiddit-pg:/tmp/
docker exec -i udiddit-pg psql -U udiddit -d udiddit -f /tmp/validation_queries.sql
```

Cleanup:
```sh
docker rm -f udiddit-pg
```
