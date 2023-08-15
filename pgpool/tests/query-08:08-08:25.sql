\set scale 1
\set naccounts 100000 * :scale - 1000
\set aid    random(1,:naccounts)
BEGIN;
SELECT
  COUNT(*)
FROM
  pgbench_accounts
  INNER JOIN pgbench_branches
  ON pgbench_accounts.bid = pgbench_branches.bid
WHERE pgbench_accounts.aid>=:aid AND pgbench_accounts.aid<=:aid+1000;
END;
