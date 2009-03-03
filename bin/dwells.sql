create table dwells_nonzero as select
	trip,
	trip_line,
	direction,
	orig_code,
	dest_code,
	code,
	i.time as time_in,
	o.time as time_out,
	o.time - i.time as time
from trips
	join stops_indexed i using (trip)
	join stops_indexed o using (trip,code)
where
	i.index + 1 = o.index;

create table dwells_zero as select
	trip,
	trip_line,
	direction,
	orig_code,
	dest_code,
	code,
	time as time_in,
	time as time_out,
	0 as time
from trips
	join stops using (trip);

create view dwells as
	select * from dwells_nonzero union
	select * from dwells_zero;

create table dwells_aggregate as select
	trip_line,
	direction,
	orig_code,
	dest_code,
	code,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from dwells group by
	trip_line,
	direction,
	dest_code,
	orig_code,
	code
order by
	trip_line,
	direction,
	dest_code,
	orig_code,
	code;

delete from dwells_aggregate where max_time = 0;
