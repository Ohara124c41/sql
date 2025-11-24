# SQL Projects Workspace

This repository contains multiple SQL projects. Current subprojects:
- `deforestation_exploration/` – Udacity deforestation analysis (see that folder’s README for details).
- `social_news_aggregator/` – Udiddit schema redesign, migration, and validation.

## Social News Aggregator (Udiddit)
Key files:
- `social_news_aggregator/instructions.md` – full project write-up, DDL/DML, rubric notes, optional DQL.
- `social_news_aggregator/schema.sql` – normalized 5-table schema with constraints and indexes.
- `social_news_aggregator/migration.sql` – data migration from `bad_posts`/`bad_comments`.
- `social_news_aggregator/validation_queries.sql` – helper queries for checks and sample DQL.
- `social_news_aggregator/bad-db.sql` – source data (bad schema).

### Run locally with Docker (Postgres 15)
```sh
docker context use desktop-linux    # if using Docker Desktop on Windows/WSL
docker run --name udiddit-pg -e POSTGRES_PASSWORD=password -e POSTGRES_USER=udiddit -e POSTGRES_DB=udiddit -p 55432:5432 -d postgres:15
```

### Load bad data then migrate
```sh
# load source
docker cp social_news_aggregator/bad-db.sql udiddit-pg:/tmp/
docker exec -i udiddit-pg psql -U udiddit -d udiddit -f /tmp/bad-db.sql

# create normalized schema
docker cp social_news_aggregator/schema.sql udiddit-pg:/tmp/
docker exec -i udiddit-pg psql -U udiddit -d udiddit -f /tmp/schema.sql

# migrate data (truncate first only if re-running)
docker cp social_news_aggregator/migration.sql udiddit-pg:/tmp/
docker exec -i udiddit-pg psql -U udiddit -d udiddit -f /tmp/migration.sql
```

### Quick validation
```sh
docker exec udiddit-pg psql -U udiddit -d udiddit -c "SELECT count(*) FROM users;"
docker exec udiddit-pg psql -U udiddit -d udiddit -c "SELECT count(*) FROM topics;"
docker exec udiddit-pg psql -U udiddit -d udiddit -c "SELECT count(*) FROM posts;"
docker exec udiddit-pg psql -U udiddit -d udiddit -c "SELECT count(*) FROM comments;"
docker exec udiddit-pg psql -U udiddit -d udiddit -c "SELECT count(*) FROM votes;"
```
Expected counts with provided data: `users=11077`, `topics=89`, `posts=50000`, `comments=100000`, `votes≈499710`.

### Cleanup
```sh
docker rm -f udiddit-pg
```
