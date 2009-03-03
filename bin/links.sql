drop table links, links_aggregate cascade;

create table links as select
	trip, route,
	o.code as code_out,
	i.code as code_in,
	o.time as time_out,
	i.time as time_in,
	i.time - o.time as time
from trips natural join route_trips
	join stops_indexed o using (trip)
	join stops_indexed i using (trip)
where
	o.code <> i.code and
	o.index + 1 = i.index;

create table links_aggregate as select
	route, code_out, code_in,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from links
group by route, code_out, code_in
order by route, code_out, code_in;
