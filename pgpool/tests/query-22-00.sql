\set nbranches :scale
\set ntellers 10 * :scale
\set naccounts 100000 * :scale - 1000
\set aid    random(1,:naccounts)
\set bid    random(1,:nbranches)
\set tid    random(1,:ntellers)
\set delta  random(-5000,5000)
\set choice random(-100,100)
BEGIN;
\if :choice <=-90
  UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
  UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
  UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
\else
  SELECT
    COUNT(*)
  FROM
    pgbench_accounts
    INNER JOIN pgbench_branches
    ON pgbench_accounts.bid = pgbench_branches.bid
  WHERE pgbench_accounts.aid>=:aid AND pgbench_accounts.aid<=:aid+1000;
\endif
END;

