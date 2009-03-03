drop table dwells, dwells_aggregate cascade;

create temp table dwells_nonzero as select
	trip, route, code,
	i.time as time_in,
	o.time as time_out,
	o.time - i.time as time
from trips natural join route_trips
	join stops_indexed i using (trip)
	join stops_indexed o using (trip,code)
where
	i.index + 1 = o.index;

create temp view dwells_zero as select
	trip, route, code,
	time as time_in,
	time as time_out,
	0 as time
from trips natural join route_trips
	join stops using (trip);

create table dwells as
	select * from dwells_nonzero union
	select * from dwells_zero;

create table dwells_aggregate as select
	route, code,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from dwells group by route, code
order by route, code;
