delete from trips where service <> 1;
delete from stops where not stop;
alter table stops drop column stop;

create index stops_trip_idx on stops (trip);
create index stops_code_idx on stops (code);
create index stops_time_idx on stops (time);

update stops set code='718' where code='R09';

create temp view stop_codes as
	select distinct code from stops where stop;

create temp view real_stations as
	select * from stations natural join stop_codes
	where x is not null and y is not null;

delete from stations where code not in (select code from real_stations);
