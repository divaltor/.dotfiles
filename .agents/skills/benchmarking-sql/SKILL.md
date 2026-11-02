---
name: benchmarking-sql
description: "Choose SQL benchmark metrics and explain results for query rewrites, stored procedures, joins, staging, pruning, indexes, DML and file formats. Covers latency, server CPU, I/O, memory, spill, correctness and cost, including Redshift/Spectrum. Use when asked to benchmark SQL, compare query performance or interpret query plans."
---

# Benchmarking SQL

Choose measurements from the question being tested, not from a fixed harness. Use the project's tools or write an experiment-specific script; this skill supplies no runner, templates, credential policy or execution restrictions. The user's task defines the permitted operations.

## Choose the evidence

Start by stating the hypothesis and primary objective. Use the matching row below; combine rows when a change affects several kinds of work.

| What changes? | Measure | Why |
|---|---|---|
| Query or application latency | End-to-end elapsed time, server execution, queue, compile/planning and lock wait separately | Less database work need not reduce the time the caller waits. |
| Predicates, expressions or repeated scans | Server CPU core-seconds, rows/blocks read, execution time and scan predicates | Distinguishes cheaper per-row computation from reading fewer rows. |
| Joins, distribution or lookup tables | Whole-pipeline elapsed including lookup copy/ANALYZE, redistribution/broadcast, per-slice rows/time, spill and allocated memory | A faster join can hide preparation costs or move a bottleneck to one worker. |
| Procedure or staging rewrite | Whole-pipeline and per-step elapsed, statement count, rows written, CPU and read/write blocks | Fewer statements and discarded staging rows can save work even when cluster load hides latency gains. |
| Indexes, sort keys or date pruning | Actual plan, rows/blocks read versus returned, range scans, buffer/cache reads and layout/statistics | A promising predicate or index is useful only if the measured plan avoids work. |
| Spectrum partitions or file formats | Source bytes scanned, files, total/qualified partitions, returned rows/bytes, execution and end-to-end time | Smaller scans may still execute more slowly; partition coverage also determines which data exists to query. |
| UPDATE, DELETE or MERGE | Matched and actually changed rows, write blocks, execution/commit, deleted-row growth and maintenance work | A SELECT/count measures the read path, not rewriting rows, commits or later vacuum. |
| Conversion or storage cost | Download, conversion, upload, catalog and validation time; output bytes, converter CPU/RSS, actual billed scan units and execution frequency | Query savings alone omit the cost of producing and retaining the new format. |

For memory questions, distinguish process peak RSS, database working-memory allocations and spill. They describe different resources; an allocation is not peak server RAM. Client CPU/RSS describe the benchmark script, not the database.

## Shape the comparison

1. Identify the actual baseline: deployed definition, candidate ref, callers and relevant table layout. Record engine/cluster, workload settings, input window, parameters and excluded steps so another run can reproduce the comparison.
2. Compare the same inputs and output semantics. Pin dates/cohorts where possible; check timezone boundaries, late arrivals, null/empty values and join multiplicity. A file date is not necessarily an event date.
3. Include every variant-specific preparation step in its pipeline total. Show common fixture creation separately. State whether targets are production tables, schema-matched clones or CTAS outputs, because layout and write behavior can differ.
4. Capture plans and query IDs alongside timings. Separate result-cache hits, first compilation, warm runs, queues and concurrency rather than silently folding them into execution time.
5. Repeat in alternating order to expose cache/load effects. Report observations and paired differences/ranges; choose repetitions from observed noise rather than claiming a fixed run count proves significance. If latency remains noisy, report the supported CPU/I/O result without calling it a latency win.
6. Validate business output, not just counts. Compare full rows with multiplicities and null semantics. Identify generated columns excluded from comparison; report floating-point discrepancies and any agreed tolerance explicitly. For intentional behavior changes, verify the intended difference instead of demanding equality.

## Find the counters

Use the engine's native statistics. PostgreSQL: `EXPLAIN (ANALYZE, BUFFERS)`; MySQL: `EXPLAIN ANALYZE` and available performance-schema counters; SQLite: query plans and available statement/scan statistics. Explain/instrumentation timings are comparative measurements, not uninstrumented production latency.

For Redshift, select the sources needed by the hypothesis:

| Evidence | Source and units | Interpretation |
|---|---|---|
| Server timing and cache | `SYS_QUERY_HISTORY`: elapsed/execution/queue/compile/planning/lock-wait in µs, result-cache flag | Keep components separate; server elapsed is not execution alone. |
| Native scans, writes, skew, spill | `SYS_QUERY_DETAIL`: step-level rows, blocks, I/O and skew | Step/segment/stream totals overlap. Parallel segment durations are not additive pipeline time. |
| Sampled CPU and native I/O | `SVL_QUERY_METRICS_SUMMARY`: `query_cpu_time` seconds, `query_blocks_read` 1 MB blocks, temp-disk MB | Sampled CPU can be coarse or zero on short queries; missing counters are unavailable, not zero. |
| Spectrum source scans | `SVL_S3QUERY_SUMMARY`: `s3_scanned_bytes`, files; `SYS_EXTERNAL_QUERY_DETAIL`: partitions/files and returned rows/bytes | Returned bytes are not source bytes scanned or automatically billable bytes. |
| Working memory | `SVL_QUERY_REPORT`: `workmem` bytes and `is_diskbased` per step/slice | Allocations and spill are pressure evidence, not peak cluster or Spectrum-service RAM. |

Match statements by session and unique query tag. SYS and legacy STL/SVL query IDs are different namespaces; verify their mapping before joining metrics. Legacy sources may be absent on Serverless or concurrency scaling. For totals, sum distinct statement counters at the same scope and state coverage; use maxima/distributions for memory and skew rather than sums. Logical reads are not proof of physical disk reads.

## Explain the result

Report the scope, repetitions and exclusions, then a before/after table for the chosen metrics with units. Connect each claimed improvement to the observed plan or workload change. Separate measured results, read-path proxies and extrapolations. A scan reduction does not automatically save provisioned-cluster dollars; cost claims need the billing model, regional price and actual frequency.

Recent `Financial-Times/biteam-engineering` examples illustrate which evidence matters (prior reports, not results reproduced by this skill):

- [#562](https://github.com/Financial-Times/biteam-engineering/pull/562): PTT CPU, read blocks, statement count and staging writes; baseline wall time varied 57–135 s, so latency was not claimed.
- [#564](https://github.com/Financial-Times/biteam-engineering/pull/564): lookup preparation included in 402.6→112.2 s pipeline replay; `DS_DIST_ALL_NONE` and exact output multiplicities explain the result. One run per side is descriptive evidence.
- [#565](https://github.com/Financial-Times/biteam-engineering/pull/565), [#568](https://github.com/Financial-Times/biteam-engineering/pull/568): read-only scan probes plus predicate placement, skew and hash equality; these do not time UPDATE rewrites.
- [#566](https://github.com/Financial-Times/biteam-engineering/pull/566), [#567](https://github.com/Financial-Times/biteam-engineering/pull/567): already-null versus changed rows and weekly cohort coverage; performance measurements must preserve intended erasure behavior and explain audit-count changes.
- [#556](https://github.com/Financial-Times/biteam-engineering/pull/556), [#558](https://github.com/Financial-Times/biteam-engineering/pull/558): actual scan pruning, date boundaries and registered partition coverage; inspect the engine's plan rather than assuming every date cast prevents pruning.
