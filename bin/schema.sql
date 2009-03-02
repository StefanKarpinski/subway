drop table stations cascade;
drop table trips cascade;
drop table stops cascade;

create table stations (
	line text,
	code text primary key,
	short text,
	long text,
	coords point
);

create table trips (
	id serial primary key,
	line text,
	service int,
	direction text,
	orig_code text references stations (code),
	dest_code text references stations (code),
	orig_time interval,
	dest_time interval,
	trip_line text
);

create table stops (
	trip_id int references trips,
	code text references stations,
	track text,
	time interval,
	type text,
	stop boolean,
	timepoint boolean
);
