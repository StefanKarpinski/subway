create index stops_trip_idx on stops (trip);
create index stops_code_idx on stops (code);
create index stops_time_idx on stops (time);
create index stops_type_idx on stops (type);

update stops set code='718' where code='R09';

create temp view used_codes as select distinct code
	from stops natural join stations
	where x is not null and y is not null;

delete from stations where code not in (select code from used_codes);
