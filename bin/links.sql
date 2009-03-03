create table links as select
	trip,
	trip_line,
	direction,
	orig_code,
	dest_code,
	o.code as code_out,
	i.code as code_in,
	o.time as time_out,
	i.time as time_in,
	i.time - o.time as time
from trips
	join stops_indexed o using (trip)
	join stops_indexed i using (trip)
where
	o.code <> i.code and
	o.index + 1 = i.index;

create table links_aggregate as select
	trip_line,
	direction,
	orig_code,
	dest_code,
	code_out,
	code_in,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from links group by
	trip_line,
	direction,
	dest_code,
	orig_code,
	code_out,
	code_in
order by
	trip_line,
	direction,
	dest_code,
	orig_code,
	code_out,
	code_in;
