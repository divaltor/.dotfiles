---
name: duckdb-query
description: Queries local and remote files (Parquet, CSV, JSON) using DuckDB as SQL engine. Use for data analysis, file inspection, S3 queries, or answering questions about tabular data.
---

# DuckDB Query Engine

Use DuckDB CLI to query local and remote data files without loading them into a database.

## Prerequisites

Ensure DuckDB is installed: `duckdb --version`. If not, install via `brew install duckdb` (macOS) or see https://duckdb.org/docs/installation.

## Workflow

### 1. For S3 Files (AWS)

**Always configure credentials first** before querying S3 paths:

```sql
-- Use AWS credential chain (reads from env, ~/.aws/credentials, IAM role, etc.)
CREATE OR REPLACE SECRET s3_secret (
    TYPE s3,
    PROVIDER credential_chain
);
```

To verify credentials work:
```sql
SELECT * FROM 's3://bucket/path/file.parquet' LIMIT 1;
```

If you need a specific profile:
```sql
CREATE OR REPLACE SECRET s3_secret (
    TYPE s3,
    PROVIDER credential_chain,
    PROFILE 'my-profile'
);
```

### 2. Query Files Directly

```bash
# Quick query (in-memory)
duckdb -c "SELECT * FROM 'data.parquet' LIMIT 10"
duckdb -c "SELECT * FROM 'data.csv' LIMIT 10"
duckdb -c "SELECT * FROM 'data.json' LIMIT 10"
duckdb -c "SELECT * FROM 'data.csv.gz' LIMIT 10"

# S3 files
duckdb -c "CREATE SECRET (TYPE s3, PROVIDER credential_chain); SELECT * FROM 's3://bucket/file.parquet' LIMIT 10"
```

### 3. Get Table Metadata

```sql
-- Column names and types
DESCRIBE SELECT * FROM 'file.parquet';

-- Or using pragma
PRAGMA table_info('file.parquet');

-- Parquet metadata
SELECT * FROM parquet_metadata('file.parquet');
SELECT * FROM parquet_schema('file.parquet');
```

### 4. Persist Data Locally (Large Files)

For large files or repeated queries, create a persistent database:

```bash
duckdb mydata.db
```

```sql
-- Create table from remote file
CREATE TABLE sales AS SELECT * FROM 's3://bucket/sales.parquet';

-- Create temporary table (session only)
CREATE TEMP TABLE temp_data AS SELECT * FROM 'large_file.csv';
```

## DuckDB-Specific Syntax

### EXCLUDE - Remove Columns from SELECT *

```sql
-- All columns except 'id' and 'created_at'
SELECT * EXCLUDE (id, created_at) FROM 'data.parquet';

-- With table alias
SELECT t.* EXCLUDE (internal_field) FROM 'data.parquet' t;
```

### REPLACE - Transform Columns in SELECT *

```sql
-- Replace 'price' with rounded value
SELECT * REPLACE (round(price, 2) AS price) FROM 'sales.parquet';

-- Multiple replacements
SELECT * REPLACE (upper(name) AS name, price * 1.1 AS price) FROM 'products.csv';
```

### COLUMNS - Dynamic Column Selection

```sql
-- Select columns matching pattern
SELECT COLUMNS('.*_id') FROM 'data.parquet';

-- Apply function to matching columns
SELECT COLUMNS('amount.*')::DECIMAL(10,2) FROM 'transactions.csv';

-- All numeric columns
SELECT MIN(COLUMNS(* EXCLUDE (name, date))) FROM 'data.parquet';

-- Using regex
SELECT COLUMNS('(first|last)_name') FROM 'users.csv';
```

### COLUMNS with Lambda

```sql
-- Select columns where name contains 'price'
SELECT COLUMNS(c -> c LIKE '%price%') FROM 'products.parquet';

-- Select only numeric columns
SELECT COLUMNS(c -> typeof(c) IN ('INTEGER', 'DOUBLE')) FROM 'data.parquet';
```

### Pattern Matching in Column Selection

```sql
-- LIKE pattern
SELECT * LIKE '%amount%' FROM 'transactions.parquet';

-- GLOB pattern
SELECT * GLOB '*_date' FROM 'events.csv';
```

## Reading Multiple Files

```sql
-- Glob patterns
SELECT * FROM 'data/*.parquet';
SELECT * FROM 'logs/2024-*.csv';

-- Multiple specific files
SELECT * FROM read_parquet(['file1.parquet', 'file2.parquet']);

-- With filename column
SELECT *, filename FROM 'data/*.parquet';

-- Hive-partitioned data
SELECT * FROM 'data/*/*.parquet' WHERE year = 2024;
```

## Output Formats

**Default: Use `-jsonlines` for compact LLM-friendly output** (one JSON object per row, no wasted tokens on table formatting):

```bash
# PREFERRED: JSONLines - compact, one object per line (best for LLM agents)
duckdb -jsonlines -c "SELECT * FROM 'data.parquet' LIMIT 5"

# JSON array - when you need a valid JSON array
duckdb -json -c "SELECT * FROM 'data.parquet' LIMIT 5"

# CSV - compact, good for exports
duckdb -csv -c "SELECT * FROM 'data.parquet' LIMIT 5"
```

**Avoid for LLM queries**: `-markdown`, `-box`, `-duckbox`, `-table` (verbose, wastes context tokens)

Only use table formats when explicitly showing results to users in documentation.

## Common Patterns

### Quick Data Exploration

```sql
-- Row count
SELECT COUNT(*) FROM 'data.parquet';

-- Sample rows
SELECT * FROM 'data.parquet' USING SAMPLE 10;

-- Distinct values in a column
SELECT DISTINCT category FROM 'products.csv';

-- Value distribution
SELECT column_name, COUNT(*) FROM 'data.parquet' GROUP BY 1 ORDER BY 2 DESC LIMIT 10;
```

### Schema Discovery

```sql
-- Infer and show schema
DESCRIBE SELECT * FROM 'unknown_file.csv';

-- Check for nulls
SELECT COUNT(*) - COUNT(column_name) AS null_count FROM 'data.parquet';
```

## Reference

- [DuckDB Documentation](https://duckdb.org/docs/)
- [S3 API Support](https://duckdb.org/docs/extensions/httpfs/s3api)
- [Star Expression (EXCLUDE/COLUMNS)](https://duckdb.org/docs/sql/expressions/star)
