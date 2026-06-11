# Vector DB RAG Context Pipeline

The vector store for the [RAG Context Pipeline](../): Postgres + the `pgvector`
extension, run locally via Docker. One of the per-concern repos the pipeline is
split into (`backend-`, `engine-`, `indexing-`, `vector-db-rag-context-pipeline`).
This repo owns the **database service only**.

## Contents

```
docker-compose.yml    # pgvector/pgvector:pg17 service (publishes localhost:5432)
db/
└── init.sql          # CREATE EXTENSION vector (runs once on first container start)
```

The `chunks` table itself is **not** defined here — it's created/replaced by the
indexing pipeline (`indexing-rag-context-pipeline/build_index.py`). `init.sql` only enables the
`vector` extension on the empty data volume the first time the container starts.

## Run

```bash
docker compose up -d        # start Postgres + pgvector
docker compose down         # stop (data persists in the pgdata volume)
docker compose down -v      # stop and wipe the database
```

The service listens on `localhost:5432` with user/password/db all `rag` — i.e.
`DATABASE_URL=postgresql://rag:rag@localhost:5432/rag`, which the indexing,
engine, and backend sides read from their `.env`.

## Required by

The Postgres container is a prerequisite for building the index
(`indexing-rag-context-pipeline/build_index.py`), the REPL + eval
(`engine-rag-context-pipeline/ask.py`, `engine-rag-context-pipeline/eval/run_eval.py`),
and the [backend API](../backend-rag-context-pipeline/) —
all of which connect via `DATABASE_URL`.
