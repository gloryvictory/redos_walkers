-- 1. Установить расширение CREATE EXTENSION pg_stat_statements;
-- 2. Запустить CREATE OR REPLACE PROCEDURE gstat.stats_table()
-- 3. CALL stats_table();

CALL stats_table();


CREATE OR REPLACE PROCEDURE gstat.stats_table()
LANGUAGE plpgsql
AS $procedure$
begin
--my_db1
INSERT into test select * from dblink('postgres://postgres:postgres_password@<SERVER>/my_db1?sslmode=disable', 'select ''my_db1'',schemaname, relname, n_live_tup AS EstimatedCount FROM pg_stat_user_tables ORDER BY relname ASC') 
as t1 (name varchar, schema varchar, relname varchar, count int) ON CONFLICT (database, owner, table_name) DO update set numrow=EXCLUDED.numrow;
--my_db2
INSERT into test select * from dblink('postgres://postgres:postgres_password@<SERVER>/my_db2?sslmode=disable', 'select ''my_db2'',schemaname, relname, n_live_tup AS EstimatedCount FROM pg_stat_user_tables ORDER BY relname ASC') 
as t1 (name varchar, schema varchar, relname varchar, count int) ON CONFLICT (database, owner, table_name) DO update set numrow=EXCLUDED.numrow;


-- и т.д. и т.п.


--test
INSERT into test select * from dblink('postgres://postgres:postgres_password@<SERVER>/test?sslmode=disable', 'select ''test'',schemaname, relname, n_live_tup AS EstimatedCount FROM pg_stat_user_tables ORDER BY relname ASC') 
as t1 (name varchar, schema varchar, relname varchar, count int) ON CONFLICT (database, owner, table_name) DO update set numrow=EXCLUDED.numrow;
END $procedure$;