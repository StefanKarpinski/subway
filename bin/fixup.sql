create index stops_trip_idx on stops (trip);
create index stops_code_idx on stops (code);
create index stops_time_idx on stops (time);
create index stops_type_idx on stops (type);

update stops set code='718' where code='R09';

create temp view codes as select distinct code from stops;
create temp view used_stations as
	select * from stations natural join codes
	where x is not null and y is not null;

delete from stations where code not in (select code from used_stations);
