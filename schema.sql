-- ============================================================
-- A4 SQL Tests — Table Schemas
-- Compatible with: PostgreSQL, MySQL, SQLite
-- ============================================================

-- ── Scenario 1: Round-Trip Transfer Detection ────────────────
CREATE TABLE transactions (
    transaction_id   INTEGER      PRIMARY KEY AUTOINCREMENT,
    sender_account   VARCHAR(20)  NOT NULL,
    receiver_account VARCHAR(20)  NOT NULL,
    amount           DECIMAL(12,2) NOT NULL,
    transaction_date DATETIME     NOT NULL
);

-- Sample data
INSERT INTO transactions (sender_account, receiver_account, amount, transaction_date) VALUES
-- ✅ Round-trip: exact same amount, 9.5 hours apart
('A001', 'A002',  5000.00, '2024-03-01 09:00:00'),
('A002', 'A001',  5000.00, '2024-03-01 18:30:00'),
-- ✅ Round-trip: 2% difference, 12 hours apart
('A003', 'A004', 10000.00, '2024-03-02 08:00:00'),
('A004', 'A003',  9800.00, '2024-03-02 20:00:00'),
-- ❌ NOT a round-trip: return came 27 hours later (exceeds 24h)
('A005', 'A006',  3000.00, '2024-03-03 07:00:00'),
('A006', 'A005',  3000.00, '2024-03-04 10:00:00'),
-- ❌ NOT a round-trip: 25% amount difference (exceeds 10%)
('A007', 'A008',  8000.00, '2024-03-04 10:00:00'),
('A008', 'A007',  6000.00, '2024-03-04 14:00:00'),
-- ✅ Round-trip: 2% difference, 2 hours apart
('A009', 'A010', 25000.00, '2024-03-05 11:00:00'),
('A010', 'A009', 24500.00, '2024-03-05 13:00:00'),
-- ❌ One-way only (no return)
('A001', 'A003',  1500.00, '2024-03-06 09:00:00'),
('A002', 'A005',  2200.00, '2024-03-06 11:00:00');


-- ── Scenario 2: IPL Player Performance Streaks ───────────────
CREATE TABLE ipl_performances (
    performance_id INTEGER      PRIMARY KEY AUTOINCREMENT,
    player_name    VARCHAR(100) NOT NULL,
    match_date     DATE         NOT NULL,
    match_number   INTEGER      NOT NULL,
    runs_scored    INTEGER      NOT NULL,
    opponent       VARCHAR(50)  NOT NULL
);

-- Sample data — IPL 2024 season
INSERT INTO ipl_performances (player_name, match_date, match_number, runs_scored, opponent) VALUES
-- Virat Kohli: 5 consecutive 30+ ✅
('Virat Kohli',       '2024-03-22', 1,  72, 'CSK'),
('Virat Kohli',       '2024-03-26', 2,  45, 'MI'),
('Virat Kohli',       '2024-03-30', 3,  88, 'RR'),
('Virat Kohli',       '2024-04-03', 4,  31, 'KKR'),
('Virat Kohli',       '2024-04-07', 5,  56, 'SRH'),
('Virat Kohli',       '2024-04-11', 6,  18, 'GT'),
('Virat Kohli',       '2024-04-15', 7,  43, 'PBKS'),
-- Rohit Sharma: 3 consecutive 30+ ✅
('Rohit Sharma',      '2024-03-23', 1,  65, 'RCB'),
('Rohit Sharma',      '2024-03-27', 2,  34, 'KKR'),
('Rohit Sharma',      '2024-03-31', 3,  91, 'SRH'),
('Rohit Sharma',      '2024-04-04', 4,  22, 'CSK'),
-- Shubman Gill: only 2 consecutive ❌
('Shubman Gill',      '2024-03-24', 1,  55, 'MI'),
('Shubman Gill',      '2024-03-28', 2,  38, 'RCB'),
('Shubman Gill',      '2024-04-01', 3,  12, 'PBKS'),
('Shubman Gill',      '2024-04-05', 4,  47, 'CSK'),
-- KL Rahul: 4 consecutive 30+ ✅
('KL Rahul',          '2024-03-25', 1,  78, 'GT'),
('KL Rahul',          '2024-03-29', 2,  33, 'SRH'),
('KL Rahul',          '2024-04-02', 3,  62, 'MI'),
('KL Rahul',          '2024-04-06', 4,  45, 'RR'),
('KL Rahul',          '2024-04-10', 5,  19, 'KKR'),
-- Hardik Pandya: never 3 consecutive ❌
('Hardik Pandya',     '2024-03-22', 1,  42, 'RCB'),
('Hardik Pandya',     '2024-03-26', 2,  15, 'GT'),
('Hardik Pandya',     '2024-03-30', 3,  38, 'CSK'),
('Hardik Pandya',     '2024-04-03', 4,  21, 'SRH'),
('Hardik Pandya',     '2024-04-07', 5,  55, 'RR'),
-- Suryakumar Yadav: 3 consecutive in middle ✅
('Suryakumar Yadav',  '2024-03-22', 1,  25, 'KKR'),
('Suryakumar Yadav',  '2024-03-26', 2,  82, 'PBKS'),
('Suryakumar Yadav',  '2024-03-30', 3,  47, 'RCB'),
('Suryakumar Yadav',  '2024-04-03', 4,  31, 'GT'),
('Suryakumar Yadav',  '2024-04-07', 5,  18, 'CSK');
