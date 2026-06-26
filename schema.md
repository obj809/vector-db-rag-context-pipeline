# `chunks` table schema

The vector store is a single table, `chunks`. **It is not defined in this repo.**
This repo's `db/init.sql` only enables the `pgvector` extension on first container
start (`CREATE EXTENSION vector`); the table itself is created — and dropped + recreated
on every build — by the indexing pipeline:
[`indexing-rag-context-pipeline/build_index.py`](../indexing-rag-context-pipeline/build_index.py).

It's documented here because this repo owns the database that holds it, and because
the table is the contract every other repo communicates through (the indexing side
writes it; the engine and backend read it).

## Schema

```sql
CREATE TABLE chunks (
    id              SERIAL PRIMARY KEY,
    content         TEXT NOT NULL,
    embedding       VECTOR(dim) NOT NULL,   -- dim derived from the embedding model (384 for bge-small)
    embedding_model TEXT NOT NULL,
    page            INTEGER,
    volume          TEXT
);
```

| Column            | Type          | Notes |
| ----------------- | ------------- | ----- |
| `id`              | `SERIAL`      | Primary key. |
| `content`         | `TEXT`        | The chunk's text (per-page Markdown, recursively split). |
| `embedding`       | `VECTOR(dim)` | The chunk vector. `dim` is set at build time from the embedding model's output dimension (384 for `BAAI/bge-small-en-v1.5`), so the column width tracks whatever model the build used. No ANN index — for a single PDF an exact sequential scan is instant; add an HNSW index (`vector_cosine_ops`) only if the corpus grows. |
| `embedding_model` | `TEXT`        | The model name used to embed the chunk. Stored alongside the data so the query side can't accidentally embed a query with a different model — the single non-obvious piece of glue holding the cross-repo contract together. |
| `page`            | `INTEGER`     | 1-indexed page, from the loader's per-page metadata. |
| `volume`          | `TEXT`        | `"Volume 1"`/`2`/`3`, derived from the source filename. |

Pages restart at 1 in each volume, so `page` alone is ambiguous — `(volume, page)`
together form a citation, surfaced in answers as `[Volume N, p.M]`.

## How it's created

The table is created with `DROP TABLE IF EXISTS chunks` followed by `CREATE TABLE`,
so each `build_index.py` run is idempotent and the `VECTOR(dim)` always matches the
current model. Changing the embedding model and rebuilding just works: the new
dimension and model name are recorded on rebuild, and the query side picks the model
up automatically by reading the `embedding_model` column.

Retrieval queries the table with cosine distance:

```sql
SELECT content, page, volume FROM chunks ORDER BY embedding <=> %s LIMIT %s;
```
