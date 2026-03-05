-- Выбрать все таблицы у которых есть колонка с координатами "geom"

select b.tablename from pg_tables b
left join pg_class c on b.tablename = c.relname
left join pg_attribute a on c.oid=a.attrelid
where
b.schemaname <>'pg_catalog' and a.attname='geom'
order by b.tablename