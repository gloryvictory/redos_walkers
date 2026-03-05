-- connect as postgres to postgres
-- "my_db"
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'my_db'
AND pid <> pg_backend_pid();

ALTER DATABASE "my_db" RENAME TO "my_db_new";


-- если надо то создаем БД
-- CREATE ROLE my_user WITH SUPERUSER LOGIN CREATEDB CREATEROLE  ENCRYPTED PASSWORD  'my_user_password';
-- CREATE DATABASE "my_db" WITH OWNER "my_user";
-- GRANT ALL PRIVILEGES ON DATABASE "my_db" TO "my_user";
-- \c my_db;

-- CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;


