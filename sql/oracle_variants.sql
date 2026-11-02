/*
 * Tests with output that depends on the PostgreSQL or Oracle version.
 *
 * CI combinations (PostgreSQL / Oracle Server / Instant Client):
 * oracle_variants_0.out: 18 / XE 21.3 / 19.32.
 * oracle_variants_1.out: 18 / Free 23.26.3 / 23.26.3.
 * pg_regress selects the matching expected file automatically.
 */

-- will fail with a read-only transaction
ALTER SERVER oracle OPTIONS (ADD isolation_level 'read_only');
SELECT oracle_close_connections();
DELETE FROM typetest1;

-- use the default SERIALIZABLE isolation level from now on
ALTER SERVER oracle OPTIONS (DROP isolation_level);
SELECT oracle_close_connections();

-- transactions
BEGIN;
DELETE FROM shorty WHERE id = 2;
SAVEPOINT one;
-- will cause an error
INSERT INTO shorty (id, c) VALUES (1, 'c');
ROLLBACK TO one;
INSERT INTO typetest1 (id, c) VALUES (2, 'c');
ROLLBACK TO one;
SELECT id FROM shorty WHERE id = 1;
COMMIT;

-- test if "IN" or "= ANY" expressions are pushed down correctly
EXPLAIN (COSTS off) SELECT id FROM typetest1 WHERE vc = ANY (ARRAY['short', (SELECT 'varlena'::varchar)]) ORDER BY id;
SELECT id FROM typetest1 WHERE vc = ANY (ARRAY['short', (SELECT 'varlena'::varchar)]) ORDER BY id;

/* default setting sometimes leads to merge joins */
SET enable_mergejoin = off;
-- inner rel is false, not pushed down
EXPLAIN (COSTS off)
SELECT 1 FROM (SELECT 1 FROM typetest1  WHERE false) AS subq1 RIGHT JOIN typetest1  AS ref1 ON NULL ORDER BY ref1.id;
SELECT 1 FROM (SELECT 1 FROM typetest1  WHERE false) AS subq1 RIGHT JOIN typetest1  AS ref1 ON NULL ORDER BY ref1.id;
-- semi-join, not pushed down
EXPLAIN (COSTS off)
SELECT t1.id FROM typetest1  t1 WHERE EXISTS (SELECT 1 FROM typetest1  t2 WHERE t1.d = t2.d) ORDER BY t1.id;
SELECT t1.id FROM typetest1  t1 WHERE EXISTS (SELECT 1 FROM typetest1  t2 WHERE t1.d = t2.d) ORDER BY t1.id;
