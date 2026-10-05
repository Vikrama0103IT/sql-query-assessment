# A4 — SQL Setup & Steps

Step-by-step guide to run both SQL scenarios and commit results to GitHub.

---

## Prerequisites

No special installation required. Choose any one option:

| Option | Tool needed | Where to get |
|---|---|---|
| A | `sqlite3` CLI | Pre-installed on macOS/Linux. Windows: https://sqlite.org/download.html |
| B | Browser only | https://sqliteonline.com (free, no sign-up) |
| C | Python 3 | Pre-installed on most systems |

---

## Files in this folder

| File | Purpose |
|---|---|
| `schema.sql` | Creates both tables and inserts sample data |
| `round_trip_transfers.sql` | Scenario 1 query — round-trip detection |
| `ipl_streaks.sql` | Scenario 2 query — IPL consecutive streak |
| `screenshots/scenario1_output.txt` | Committed output of Scenario 1 |
| `screenshots/scenario2_output.txt` | Committed output of Scenario 2 |

---

## Step 1 — Run Scenario 1 (Round-Trip Transfers)

### Using SQLite CLI

```bash
cd sql/

# Load schema + run query in one command
cat schema.sql round_trip_transfers.sql | sqlite3
```

### Using Online Compiler (sqliteonline.com)

1. Open https://sqliteonline.com
2. Click **File → New** to start fresh
3. Copy and paste the full contents of `schema.sql` into the editor
4. Click **Run** — both tables will be created with sample data
5. Clear the editor
6. Copy and paste `round_trip_transfers.sql`
7. Click **Run**

### Expected output

```
forward_txn_id  account_a  account_b  forward_amount  forward_date          return_txn_id  return_amount  return_date           amount_diff_pct  hours_apart
1               A001       A002       5000.0          2024-03-01 09:00:00   2              5000.0         2024-03-01 18:30:00   0.0              9.5
3               A003       A004       10000.0         2024-03-02 08:00:00   4              9800.0         2024-03-02 20:00:00   2.0              12.0
9               A009       A010       25000.0         2024-03-05 11:00:00   10             24500.0        2024-03-05 13:00:00   2.0              2.0
```

**3 rows returned** — only the valid round-trip pairs.

---

## Step 2 — Run Scenario 2 (IPL Streaks)

### Using SQLite CLI

```bash
# Load schema + run query
cat schema.sql ipl_streaks.sql | sqlite3
```

### Using Online Compiler

1. Keep `schema.sql` data loaded from Step 1 (or reload it)
2. Clear the editor
3. Paste contents of `ipl_streaks.sql`
4. Click **Run**

### Expected output

```
player_name          streak_commenced  streak_end_date  consecutive_matches  min_runs  max_runs  total_runs
Virat Kohli          2024-03-22        2024-04-07       5                    31        88        292
KL Rahul             2024-03-25        2024-04-06       4                    33        78        218
Rohit Sharma         2024-03-23        2024-03-31       3                    34        91        190
Suryakumar Yadav     2024-03-26        2024-04-03       3                    31        82        160
```

**4 players returned** — sorted by streak length (longest first).

---

## Step 3 — Take screenshots

Take a screenshot of each query result in your SQL tool and save them as:

```
sql/screenshots/scenario1_output.png
sql/screenshots/scenario2_output.png
```

> The `.txt` output files are already committed as evidence. Screenshots are an additional bonus for visual proof.

---

## Step 4 — Commit everything to GitHub

```bash
git add sql/
git commit -m "feat: A4 — SQL queries with schema, sample data and query outputs"
git push origin main
```

---

## Step 5 — Verify on GitHub

After pushing, confirm these files are visible in your repository:

- [ ] `sql/schema.sql`
- [ ] `sql/round_trip_transfers.sql`
- [ ] `sql/ipl_streaks.sql`
- [ ] `sql/screenshots/scenario1_output.txt`
- [ ] `sql/screenshots/scenario2_output.txt`
- [ ] `sql/README.md`
- [ ] `sql/SETUP_STEPS.md`

---

## How to verify results manually

### Scenario 1 — check the exclusions

Run this query to confirm excluded pairs:

```sql
-- Should return A005/A006 (time) and A007/A008 (amount) — both NOT in main results
SELECT sender_account, receiver_account, amount, transaction_date
FROM transactions
WHERE (sender_account = 'A005' OR sender_account = 'A006'
    OR sender_account = 'A007' OR sender_account = 'A008');
```

### Scenario 2 — check individual player data

```sql
-- See all performances for a specific player
SELECT player_name, match_date, runs_scored,
       CASE WHEN runs_scored >= 30 THEN 'YES' ELSE 'no' END AS qualifies
FROM ipl_performances
WHERE player_name = 'Virat Kohli'
ORDER BY match_date;
```
