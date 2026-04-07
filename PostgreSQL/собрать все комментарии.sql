-- Оно генерирует валидные DDL-команды COMMENT ON TABLE и COMMENT ON COLUMN,
-- Если нужны комментарии только по определённой схеме
-- Добавьте в оба CTE условие:
-- AND n.nspname = 'your_schema_name'

WITH table_comments AS (
    SELECT 
        1 AS sort_type,
        n.nspname AS schema_name,
        c.relname AS table_name,
        NULL::text AS column_name,
        'COMMENT ON TABLE ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || 
        ' IS ' || quote_literal(d.description) || ';' AS ddl
    FROM pg_description d
    JOIN pg_class c ON d.objoid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE d.objsubid = 0
      AND c.relkind IN ('r', 'p') -- 'r' = обычная таблица, 'p' = секционированная
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
),
col_comments AS (
    SELECT 
        2 AS sort_type,
        n.nspname AS schema_name,
        c.relname AS table_name,
        a.attname AS column_name,
        'COMMENT ON COLUMN ' || quote_ident(n.nspname) || '.' || quote_ident(c.relname) || '.' || quote_ident(a.attname) || 
        ' IS ' || quote_literal(d.description) || ';' AS ddl
    FROM pg_description d
    JOIN pg_class c ON d.objoid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_attribute a ON d.objoid = a.attrelid AND d.objsubid = a.attnum
    WHERE d.objsubid > 0
      AND c.relkind IN ('r', 'p')
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
      AND a.attnum > 0 -- исключаем системные колонки
)
SELECT ddl 
FROM (SELECT * FROM table_comments UNION ALL SELECT * FROM col_comments) t
ORDER BY sort_type, schema_name, table_name, column_name;