--
-- insert with DEFAULT in the target_list
--
CREATE EXTENSION sqlite_fdw;
CREATE SERVER sqlite_svr FOREIGN DATA WRAPPER sqlite_fdw
OPTIONS (database '/tmp/sqlitefdw_test_core.db');
CREATE FOREIGN TABLE inserttest01 (col1 int4, col2 int4 NOT NULL, col3 text default 'testing') SERVER sqlite_svr;
insert into inserttest01 (col1, col2, col3) values (DEFAULT, DEFAULT, DEFAULT);
insert into inserttest01 (col2, col3) values (3, DEFAULT);
insert into inserttest01 (col1, col2, col3) values (DEFAULT, 5, DEFAULT);
insert into inserttest01 values (DEFAULT, 5, 'test');
insert into inserttest01 values (DEFAULT, 7);

select * from inserttest01;

--
-- insert with similar expression / target_list values (all fail)
--
insert into inserttest01 (col1, col2, col3) values (DEFAULT, DEFAULT);
insert into inserttest01 (col1, col2, col3) values (1, 2);
insert into inserttest01 (col1) values (1, 2);
insert into inserttest01 (col1) values (DEFAULT, DEFAULT);

select * from inserttest01;

--
-- VALUES test
--
insert into inserttest01 values(10, 20, '40'), (-1, 2, DEFAULT),
    ((select 2), (select i from (values(3)) as foo (i)), 'values are fun!');

select * from inserttest01;

--
-- TOASTed value test
--
insert into inserttest01 values(30, 50, repeat('x', 10000));

select col1, col2, char_length(col3) from inserttest01;

-- drop all foreign tables
DO $d$
declare
  l_rec record;
begin
  for l_rec in (select foreign_table_schema, foreign_table_name 
                from information_schema.foreign_tables) loop
     execute format('drop foreign table %I.%I cascade;', l_rec.foreign_table_schema, l_rec.foreign_table_name);
  end loop;
end;
$d$;
DROP SERVER sqlite_svr;
DROP EXTENSION sqlite_fdw CASCADE;