drop table links cascade;
create table links as select
	trip, route,
	o.code as code_out,
	i.code as code_in,
	o.time as time_out,
	i.time as time_in,
	i.time - o.time as time
from trips
	join stops o using (trip)
	join stops i using (trip)
where
	(o.type = 'D' or o.type = 'T') and
	(i.type = 'A' or i.type = 'T') and
	 o.stop + 1 = i.stop;

drop table links_aggregate cascade;
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
