-- ============================================================
-- A4 — Scenario 1: Round-Trip Transfer Detection
--
-- Finds cases where:
--   Account A sends money to Account B, AND
--   Account B sends a similar amount back to Account A
--   Both within a 24-hour window
--   Amount difference must be within 10%
--
-- Compatible with: PostgreSQL, MySQL 8+, SQLite
-- ============================================================

SELECT
    t1.transaction_id                                                              AS forward_txn_id,
    t1.sender_account                                                              AS account_a,
    t1.receiver_account                                                            AS account_b,
    t1.amount                                                                      AS forward_amount,
    t1.transaction_date                                                            AS forward_date,
    t2.transaction_id                                                              AS return_txn_id,
    t2.amount                                                                      AS return_amount,
    t2.transaction_date                                                            AS return_date,
    ROUND(ABS(t1.amount - t2.amount) / t1.amount * 100.0, 2)                      AS amount_diff_pct,
    ROUND(
        (JULIANDAY(t2.transaction_date) - JULIANDAY(t1.transaction_date)) * 24, 2
    )                                                                              AS hours_apart
FROM transactions t1
JOIN transactions t2
    ON  t1.sender_account    = t2.receiver_account   -- A sent to B, B sent to A
    AND t1.receiver_account  = t2.sender_account
    AND t2.transaction_date  > t1.transaction_date   -- return must come AFTER original
    AND (JULIANDAY(t2.transaction_date)
         - JULIANDAY(t1.transaction_date)) * 24 <= 24 -- within 24 hours
    AND ABS(t1.amount - t2.amount)
        / t1.amount * 100.0  <= 10.0                 -- amount within 10%
ORDER BY t1.transaction_date;


-- ── PostgreSQL / MySQL variant (replace JULIANDAY with EXTRACT) ──────────
--
-- AND EXTRACT(EPOCH FROM (t2.transaction_date - t1.transaction_date)) / 3600 <= 24
--
-- ── MySQL variant ────────────────────────────────────────────────────────
--
-- AND TIMESTAMPDIFF(HOUR, t1.transaction_date, t2.transaction_date) <= 24
