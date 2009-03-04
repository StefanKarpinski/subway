drop table if exists complexes cascade;
create table complexes (complex integer primary key, name text);
copy complexes from '/Users/stefan/projects/subway/data/complexes.csv' csv;

create temp table station_complexes (code text, complex integer);
copy station_complexes from '/Users/stefan/projects/subway/data/station_complexes.csv' csv;

alter table stations add column complex integer references complexes;
update stations set complex = sc.complex
	from station_complexes sc where stations.code = sc.code;
