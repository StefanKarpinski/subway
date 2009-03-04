drop table if exists dwells cascade;
create table dwells as select
	trip, route, code,
	i.time as time_in,
	o.time as time_out,
	o.time - i.time as time
from trips
	join stops i using (trip)
	join stops o using (trip,code,stop)
where
	(i.type = 'A' and o.type = 'D') or
	(i.type = 'T' and o.type = 'T');

drop table if exists dwells_aggregate cascade;
create table dwells_aggregate as select
	route, code,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from dwells group by route, code
order by route, code;
