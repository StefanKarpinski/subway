drop table if exists dwells cascade;
create table dwells as select
	trip, route, code,
	arrive.time as arrive_time,
	depart.time as depart_time,
	depart.time - arrive.time as time
from trips
	join stops arrive using (trip)
	join stops depart using (trip,code,stop)
where
	(arrive.type = 'A' and depart.type = 'D') or
	(arrive.type = 'T' and depart.type = 'T');

alter table dwells add primary key (trip,code);

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

alter table dwells_aggregate add primary key (route,code);
