-- ============================================================
-- A4 — Scenario 2: IPL Player Performance Streaks
--
-- Finds players who scored 30+ runs in at least 3 consecutive
-- matches during the IPL 2024 season.
-- Returns: player name and the date the streak commenced.
--
-- Technique: ROW_NUMBER() - sequential rank trick
--   Consecutive qualifying rows form the same group because
--   (overall_rank - qualifying_rank) stays constant.
--
-- Compatible with: PostgreSQL, MySQL 8+, SQLite 3.25+
-- ============================================================

WITH ranked AS (
    -- Step 1: Assign an overall row number per player by match date
    SELECT
        player_name,
        match_date,
        runs_scored,
        ROW_NUMBER() OVER (
            PARTITION BY player_name
            ORDER BY match_date
        ) AS rn
    FROM ipl_performances
),

flagged AS (
    -- Step 2: Flag rows where player scored 30 or more
    SELECT
        player_name,
        match_date,
        runs_scored,
        rn,
        CASE WHEN runs_scored >= 30 THEN 1 ELSE 0 END AS is_30_plus
    FROM ranked
),

grouped AS (
    -- Step 3: Identify consecutive groups using the rn - rank trick
    -- Within qualifying rows only, rn - ROW_NUMBER() is constant
    -- for a consecutive block, changing when the streak breaks.
    SELECT
        player_name,
        match_date,
        runs_scored,
        is_30_plus,
        rn - ROW_NUMBER() OVER (
            PARTITION BY player_name, is_30_plus
            ORDER BY match_date
        ) AS streak_group
    FROM flagged
),

streak_summary AS (
    -- Step 4: Aggregate each group, keep only streaks of 3+ matches
    SELECT
        player_name,
        MIN(match_date)  AS streak_start_date,
        MAX(match_date)  AS streak_end_date,
        COUNT(*)         AS consecutive_matches,
        MIN(runs_scored) AS min_runs,
        MAX(runs_scored) AS max_runs,
        SUM(runs_scored) AS total_runs
    FROM grouped
    WHERE is_30_plus = 1
    GROUP BY player_name, streak_group
    HAVING COUNT(*) >= 3
)

-- Final output: player name + streak start date (as required)
SELECT
    player_name,
    streak_start_date   AS streak_commenced,
    streak_end_date,
    consecutive_matches,
    min_runs,
    max_runs,
    total_runs
FROM streak_summary
ORDER BY consecutive_matches DESC, streak_start_date;

-- ── Expected output ──────────────────────────────────────────────────────
--
-- player_name          streak_commenced  streak_ended  matches  min  max  total
-- Virat Kohli          2024-03-22        2024-04-07       5      31   88    292
-- KL Rahul             2024-03-25        2024-04-06       4      33   78    218
-- Rohit Sharma         2024-03-23        2024-03-31       3      34   91    190
-- Suryakumar Yadav     2024-03-26        2024-04-03       3      31   82    160
--
-- NOT returned (correctly excluded):
--   Shubman Gill   — only 2 consecutive 30+ scores
--   Hardik Pandya  — never achieved 3 consecutive 30+ scores
