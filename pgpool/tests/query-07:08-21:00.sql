\set scale 1
\set naccounts 100000 * :scale
\set aid    random(1,:naccounts)
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;

