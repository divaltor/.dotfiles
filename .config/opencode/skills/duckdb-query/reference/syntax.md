# DuckDB Syntax Reference

## Star Expression Modifiers

### EXCLUDE

Remove specific columns from `SELECT *`:

```sql
-- Single column
SELECT * EXCLUDE (id) FROM table;

-- Multiple columns
SELECT * EXCLUDE (id, created_at, updated_at) FROM table;

-- With table prefix
SELECT t.* EXCLUDE (internal_id) FROM 'data.parquet' t;
```

### REPLACE

Transform columns within `SELECT *`:

```sql
-- Single replacement
SELECT * REPLACE (round(price, 2) AS price) FROM products;

-- Multiple replacements
SELECT * REPLACE (
    upper(name) AS name,
    price * 1.1 AS price,
    date_trunc('day', created_at) AS created_at
) FROM orders;

-- Combined with EXCLUDE
SELECT * EXCLUDE (raw_data) REPLACE (lower(email) AS email) FROM users;
```

### RENAME

Rename columns in `SELECT *`:

```sql
SELECT * RENAME (old_name AS new_name) FROM table;
SELECT * RENAME (col1 AS column_one, col2 AS column_two) FROM table;
```

## COLUMNS Expression

### Basic Patterns

```sql
-- Regex match on column names
SELECT COLUMNS('.*_id') FROM table;
SELECT COLUMNS('amount|price|cost') FROM table;
SELECT COLUMNS('^user_.*') FROM users;

-- Explicit column list
SELECT COLUMNS(['id', 'name', 'email']) FROM users;
```

### With Lambda Functions

```sql
-- Filter by column name
SELECT COLUMNS(c -> c LIKE '%amount%') FROM transactions;
SELECT COLUMNS(c -> c NOT LIKE 'internal_%') FROM data;

-- Filter by data type
SELECT COLUMNS(c -> typeof(c) = 'INTEGER') FROM table;
SELECT COLUMNS(c -> typeof(c) IN ('DOUBLE', 'DECIMAL')) FROM table;
```

### Apply Functions to Multiple Columns

```sql
-- Sum all numeric columns
SELECT SUM(COLUMNS(*)) FROM sales;

-- Min/Max across columns
SELECT MIN(COLUMNS('.*_amount')) FROM transactions;

-- Coalesce across columns
SELECT COALESCE(COLUMNS('fallback_*')) FROM config;
```

### Rename with Regex Capture Groups

```sql
-- Add prefix to columns
SELECT COLUMNS('(.*)' -> 'prefix_\1') FROM table;

-- Extract part of column name
SELECT COLUMNS('user_(.*)' -> '\1') FROM users;
```

## Pattern Matching in SELECT

```sql
-- LIKE pattern (SQL wildcards: % _)
SELECT * LIKE '%_date' FROM events;

-- GLOB pattern (shell wildcards: * ?)
SELECT * GLOB '*_id' FROM table;

-- SIMILAR TO (regex-like)
SELECT * SIMILAR TO '(first|last)_name' FROM users;
```

## COLUMNS in WHERE Clause

```sql
-- All string columns contain 'error'
SELECT * FROM logs WHERE COLUMNS(c -> typeof(c) = 'VARCHAR') LIKE '%error%';

-- Any column is NULL
SELECT * FROM data WHERE COLUMNS(*) IS NULL;
```

## UNPACK / Expanding COLUMNS

```sql
-- Coalesce across multiple columns
SELECT COALESCE(UNPACK(COLUMNS('fallback_*'))) FROM config;

-- Or using * shorthand
SELECT COALESCE(*COLUMNS('value_*')) FROM data;

-- Greatest/Least across columns  
SELECT GREATEST(*COLUMNS('score_*')) AS max_score FROM results;
```

## File Reading Functions

### Parquet

```sql
read_parquet('file.parquet')
read_parquet(['file1.parquet', 'file2.parquet'])
read_parquet('*.parquet')
read_parquet('s3://bucket/path/*.parquet')

-- With options
read_parquet('file.parquet', filename=true)
read_parquet('s3://bucket/**/*.parquet', hive_partitioning=true)
```

### CSV

```sql
read_csv('file.csv')
read_csv('file.csv.gz')  -- auto-detects compression
read_csv('file.csv', header=true, sep=',', quote='"')
read_csv('file.csv', columns={'id': 'INTEGER', 'name': 'VARCHAR'})
read_csv('file.csv', auto_detect=true, sample_size=10000)

-- Skip rows, handle nulls
read_csv('file.csv', skip=1, nullstr='NA')
```

### JSON

```sql
read_json('file.json')
read_json_auto('file.json')
read_json('file.json', format='array')  -- JSON array of objects
read_json('file.json', format='newline_delimited')  -- NDJSON
```

## Metadata Functions

```sql
-- Table/file schema
DESCRIBE SELECT * FROM 'file.parquet';
PRAGMA table_info('file.parquet');

-- Parquet-specific
SELECT * FROM parquet_metadata('file.parquet');
SELECT * FROM parquet_schema('file.parquet');
SELECT * FROM parquet_file_metadata('file.parquet');

-- Column statistics (Parquet)
SELECT * FROM parquet_kv_metadata('file.parquet');
```

## Sampling

```sql
-- Random sample (percentage)
SELECT * FROM table USING SAMPLE 10%;

-- Fixed number of rows
SELECT * FROM table USING SAMPLE 100;

-- Reproducible sample
SELECT * FROM table USING SAMPLE 10% (bernoulli, 42);

-- Reservoir sampling
SELECT * FROM table USING SAMPLE 1000 ROWS (reservoir, 42);
```

## S3 Secrets

```sql
-- AWS credential chain (default)
CREATE OR REPLACE SECRET (TYPE s3, PROVIDER credential_chain);

-- Specific profile
CREATE OR REPLACE SECRET (TYPE s3, PROVIDER credential_chain, PROFILE 'prod');

-- Explicit credentials
CREATE OR REPLACE SECRET (
    TYPE s3,
    KEY_ID 'xxx',
    SECRET 'yyy',
    REGION 'us-east-1'
);

-- R2 (Cloudflare)
CREATE OR REPLACE SECRET (TYPE r2, ACCOUNT_ID 'xxx', KEY_ID 'yyy', SECRET 'zzz');

-- GCS
CREATE OR REPLACE SECRET (TYPE gcs, KEY_ID 'xxx', SECRET 'yyy');
```

## Useful Settings

```sql
SET threads = 4;
SET memory_limit = '4GB';
SET temp_directory = '/tmp/duckdb';
SET enable_progress_bar = true;
```
