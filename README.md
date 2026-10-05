[README.md](https://github.com/user-attachments/files/33077767/README.md)
# A4 — SQL Tests

> **Streamhub QA Automation Assessment — Section A4**
> Tool: SQLite 3.45 (compatible with PostgreSQL and MySQL 8+)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Repository Structure](#2-repository-structure)
3. [Scenario 1 — Round-Trip Transfer Detection](#3-scenario-1--round-trip-transfer-detection)
4. [Scenario 2 — IPL Player Performance Streaks](#4-scenario-2--ipl-player-performance-streaks)
5. [Query Results](#5-query-results)
6. [How to Run](#6-how-to-run)

---

## 1. Overview

Two SQL scenarios written against locally created SQLite databases with realistic sample data. Both queries are fully commented, include table schema, and have their output committed to this repository.

| Scenario | File | Description |
|---|---|---|
| 1 | `round_trip_transfers.sql` | Detect round-trip money transfers within 24h and ±10% amount |
| 2 | `ipl_streaks.sql` | Find IPL players with 30+ runs in 3+ consecutive matches |

---

## 2. Repository Structure

```
sql/
├── schema.sql                    # Table definitions + sample data for both scenarios
├── round_trip_transfers.sql      # Scenario 1 query
├── ipl_streaks.sql               # Scenario 2 query
└── screenshots/
    ├── scenario1_output.txt      # Actual query output — 3 round-trip pairs found
    └── scenario2_output.txt      # Actual query output — 4 players with streak
```

---

## 3. Scenario 1 — Round-Trip Transfer Detection

### Objective

Find instances where Account A sends money to Account B, and Account B sends a similar amount (within 10%) back to Account A — both within a 24-hour window. This identifies potential payment reversals or suspicious round-trip transfers.

### Table Schema

```sql
CREATE TABLE transactions (
    transaction_id   INTEGER       PRIMARY KEY AUTOINCREMENT,
    sender_account   VARCHAR(20)   NOT NULL,
    receiver_account VARCHAR(20)   NOT NULL,
    amount           DECIMAL(12,2) NOT NULL,
    transaction_date DATETIME      NOT NULL
);
```

### Logic

| Condition | Rule |
|---|---|
| Direction match | `t1.sender = t2.receiver` AND `t1.receiver = t2.sender` |
| Time window | Return must come **after** the original, within **24 hours** |
| Amount threshold | Difference must be **≤ 10%** of the forward amount |

### Query

```sql
SELECT
    t1.transaction_id                                                   AS forward_txn_id,
    t1.sender_account                                                   AS account_a,
    t1.receiver_account                                                 AS account_b,
    t1.amount                                                           AS forward_amount,
    t1.transaction_date                                                 AS forward_date,
    t2.transaction_id                                                   AS return_txn_id,
    t2.amount                                                           AS return_amount,
    t2.transaction_date                                                 AS return_date,
    ROUND(ABS(t1.amount - t2.amount) / t1.amount * 100.0, 2)           AS amount_diff_pct,
    ROUND(
        (JULIANDAY(t2.transaction_date)
         - JULIANDAY(t1.transaction_date)) * 24, 2
    )                                                                   AS hours_apart
FROM transactions t1
JOIN transactions t2
    ON  t1.sender_account    = t2.receiver_account
    AND t1.receiver_account  = t2.sender_account
    AND t2.transaction_date  > t1.transaction_date
    AND (JULIANDAY(t2.transaction_date)
         - JULIANDAY(t1.transaction_date)) * 24 <= 24
    AND ABS(t1.amount - t2.amount) / t1.amount * 100.0 <= 10.0
ORDER BY t1.transaction_date;
```

### Sample Data Explained

| Pair | Forward | Return | Diff | Hours | Result |
|---|---|---|---|---|---|
| A001 ↔ A002 | ₹5,000 | ₹5,000 | 0% | 9.5h | ✅ Matched |
| A003 ↔ A004 | ₹10,000 | ₹9,800 | 2% | 12h | ✅ Matched |
| A005 ↔ A006 | ₹3,000 | ₹3,000 | 0% | 27h | ❌ Excluded — exceeds 24h |
| A007 ↔ A008 | ₹8,000 | ₹6,000 | 25% | 4h | ❌ Excluded — exceeds 10% |
| A009 ↔ A010 | ₹25,000 | ₹24,500 | 2% | 2h | ✅ Matched |

---

## 4. Scenario 2 — IPL Player Performance Streaks

### Objective

Using an IPL 2024 season dataset, identify players who scored 30 or more runs in at least 3 consecutive matches. Return the player's name and the date the scoring streak commenced.

### Table Schema

```sql
CREATE TABLE ipl_performances (
    performance_id INTEGER      PRIMARY KEY AUTOINCREMENT,
    player_name    VARCHAR(100) NOT NULL,
    match_date     DATE         NOT NULL,
    match_number   INTEGER      NOT NULL,
    runs_scored    INTEGER      NOT NULL,
    opponent       VARCHAR(50)  NOT NULL
);
```

### Technique — ROW_NUMBER() Window Function

The query uses a 4-step CTE approach with the **consecutive group trick**:

```
Overall ROW_NUMBER  -  Qualifying ROW_NUMBER  =  Constant (for consecutive rows)
```

When a streak breaks, the qualifying sequence resets but the overall sequence does not — creating a new group value.

```sql
WITH ranked AS (
    SELECT player_name, match_date, runs_scored,
           ROW_NUMBER() OVER (PARTITION BY player_name ORDER BY match_date) AS rn
    FROM ipl_performances
),
flagged AS (
    SELECT *, CASE WHEN runs_scored >= 30 THEN 1 ELSE 0 END AS is_30_plus
    FROM ranked
),
grouped AS (
    SELECT *,
           rn - ROW_NUMBER() OVER (
               PARTITION BY player_name, is_30_plus ORDER BY match_date
           ) AS streak_group
    FROM flagged
),
streak_summary AS (
    SELECT player_name,
           MIN(match_date) AS streak_start_date,
           MAX(match_date) AS streak_end_date,
           COUNT(*)        AS consecutive_matches
    FROM grouped
    WHERE is_30_plus = 1
    GROUP BY player_name, streak_group
    HAVING COUNT(*) >= 3
)
SELECT player_name, streak_start_date AS streak_commenced,
       streak_end_date, consecutive_matches
FROM streak_summary
ORDER BY consecutive_matches DESC, streak_start_date;
```

### Sample Data Explained

| Player | Scores | Consecutive 30+ | Result |
|---|---|---|---|
| Virat Kohli | 72, 45, 88, 31, 56, 18, 43 | 5 (matches 1–5) | ✅ Matched |
| Rohit Sharma | 65, 34, 91, 22 | 3 (matches 1–3) | ✅ Matched |
| Shubman Gill | 55, 38, 12, 47 | 2 (matches 1–2) | ❌ Excluded — only 2 consecutive |
| KL Rahul | 78, 33, 62, 45, 19 | 4 (matches 1–4) | ✅ Matched |
| Hardik Pandya | 42, 15, 38, 21, 55 | Never 3 in a row | ❌ Excluded |
| Suryakumar Yadav | 25, 82, 47, 31, 18 | 3 (matches 2–4) | ✅ Matched |

---

## 5. Query Results

### Scenario 1 Output

```
SCENARIO 1 — Round-Trip Transfer Detection (within 24h, amount diff <= 10%)

Total round-trip pairs found: 3

Fwd ID  Account A  Account B    Fwd Amount  Forward Date          Ret ID  Ret Amount  Return Date           Diff %   Hours
     1  A001       A002            5000.00  2024-03-01 09:00:00       2     5000.00  2024-03-01 18:30:00    0.00%    9.5h
     3  A003       A004           10000.00  2024-03-02 08:00:00       4     9800.00  2024-03-02 20:00:00    2.00%   12.0h
     9  A009       A010           25000.00  2024-03-05 11:00:00      10    24500.00  2024-03-05 13:00:00    2.00%    2.0h

Correctly EXCLUDED:
  A005 <-> A006 : return arrived 27 hours later  (exceeds 24h window)
  A007 <-> A008 : amount difference = 25%        (exceeds 10% threshold)
```

### Scenario 2 Output

```
SCENARIO 2 — IPL 2024: Players with 30+ runs in 3+ Consecutive Matches

Players found: 4

Player                 Streak Start    Streak End      Matches    Min    Max    Total
Virat Kohli            2024-03-22      2024-04-07            5     31     88      292
KL Rahul               2024-03-25      2024-04-06            4     33     78      218
Rohit Sharma           2024-03-23      2024-03-31            3     34     91      190
Suryakumar Yadav       2024-03-26      2024-04-03            3     31     82      160

Correctly EXCLUDED:
  Shubman Gill   : only 2 consecutive 30+ scores
  Hardik Pandya  : never achieved 3 consecutive 30+ scores
```

Full output files: `screenshots/scenario1_output.txt` and `screenshots/scenario2_output.txt`

---

## 6. How to Run

### Option A — SQLite (recommended, no install needed on most systems)

```bash
# Check if sqlite3 is available
sqlite3 --version

# Run Scenario 1
sqlite3 < schema.sql
sqlite3 < round_trip_transfers.sql

# Or combine into one command
cat schema.sql round_trip_transfers.sql | sqlite3

# Run Scenario 2
cat schema.sql ipl_streaks.sql | sqlite3
```

### Option B — Online SQL compiler (no install)

1. Go to https://sqliteonline.com or https://www.db-fiddle.com
2. Select **SQLite** as the database
3. Paste the contents of `schema.sql` into the left panel and run it
4. Then paste `round_trip_transfers.sql` or `ipl_streaks.sql` and run

### Option C — Python (used to generate the committed output)

```bash
# Requires only Python 3 — no extra packages
python3 -c "
import sqlite3
conn = sqlite3.connect(':memory:')
# paste schema + query and execute
"
```

### Option D — PostgreSQL

Replace `JULIANDAY()` with `EXTRACT(EPOCH FROM ...)` in Scenario 1:

```sql
AND EXTRACT(EPOCH FROM (t2.transaction_date - t1.transaction_date)) / 3600 <= 24
```

### Option E — MySQL 8+

Replace `JULIANDAY()` with `TIMESTAMPDIFF()`:

```sql
AND TIMESTAMPDIFF(HOUR, t1.transaction_date, t2.transaction_date) <= 24
```
