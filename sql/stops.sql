create temp sequence stop_index_seq;
create temp table stop_order as select
	trip, code, time,
	nextval('stop_index_seq') as index
from (
	select trip, code, min(time) as time from stops
	group by trip, code order by trip, time, code
) x
order by trip, time, code;

create unique index stop_order_trip_code_idx on stop_order (trip,code);
create unique index stop_order_index_idx on stop_order (index);

create temp table trip_bases as
	select trip, min(index)-1 as base
	from stop_order group by trip;

alter table stops rename to stops_old;
create table stops as select
	trip,
	index-base as stop,
	code,
	track,
	stop.time,
	type,
	tp
from stops_old stop
	left join stop_order using (trip,code)
	natural join trip_bases
order by trip, stop, time;
drop table stops_old cascade;

alter table stops add foreign key (trip) references trips;
alter table stops add foreign key (code) references stations;

create unique index stops_trip_stop_type_idx on stops (trip,stop,type);
create unique index stops_trip_code_type_idx on stops (trip,code,type);
create unique index stips_trip_time_idx on stops(trip,time);

create index stops_trip_idx on stops (trip);
create index stops_code_idx on stops (code);
create index stops_time_idx on stops (time);
create index stops_type_idx on stops (type);
