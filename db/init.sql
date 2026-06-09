-- Runs once, as superuser, on first container start (data volume empty).
-- The chunks table itself is created/replaced by indexing/build_index.py.
CREATE EXTENSION IF NOT EXISTS vector;
