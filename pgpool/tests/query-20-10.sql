I have no name!@pgbench-64f9bb76fd-ccxrm:/usr$ cat >> query.sql
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

app=> explain select COUNT(*)
FROM
  pgbench_accounts
  INNER JOIN pgbench_branches
  ON pgbench_accounts.bid = pgbench_branches.bid
WHERE pgbench_accounts.aid>=0 AND pgbench_accounts.aid<=1000;
                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=84.14..84.15 rows=1 width=8)
   ->  Hash Join  (cost=29.09..81.75 rows=956 width=0)
         Hash Cond: (pgbench_accounts.bid = pgbench_branches.bid)
         ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.56..50.68 rows=956 width=4)
               Index Cond: ((aid >= 0) AND (aid <= 1000))
         ->  Hash  (cost=24.77..24.77 rows=300 width=4)
               ->  Index Only Scan using pgbench_branches_pkey on pgbench_branches  (cost=0.27..24.77 rows=300 width=4)
(7 rows)

