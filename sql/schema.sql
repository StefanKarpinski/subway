create type borough as enum (
	'Manhattan',
	'Brooklyn',
	'Queens',
	'Bronx'
);

drop table if exists stations cascade;
create table stations (
	code text primary key,
	alt text,
	name text,
	short text,
	line text,
	borough borough,
	complex text,
	x integer,
	y integer
);

create type direction as enum ('N','S');

drop table if exists trips cascade;
create table trips (
	trip integer primary key,
	line text,
	service int,
	direction direction,
	orig_code text,
	orig_time real,
	dest_code text,
	dest_time real,
	trip_line text
);

create type stop_type as enum ('A','T','D');

drop table if exists stops cascade;
create table stops (
	trip integer references trips on delete cascade,
	code text,
	track text,
	time real,
	type stop_type,
	tp boolean,
	primary key (trip,code,type)
);

drop aggregate array_accum (anyelement);
create aggregate array_accum (anyelement)
(
    sfunc = array_append,
    stype = anyarray,
    initcond = '{}'
);
