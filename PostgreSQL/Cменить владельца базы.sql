-- меняет владельца для всех таблиц бд на указанного
-- исполнять в psql
\c "my_db"
DO $$
DECLARE
obj_record RECORD;
BEGIN
FOR obj_record IN
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
AND tableowner = 'postgres'
LOOP
EXECUTE format('ALTER TABLE %I.%I OWNER TO "new_user";',
obj_record.schemaname, obj_record.tablename);
END LOOP;
END $$;
