drop table if exists links cascade;
create table links as select
	trip, route,
	depart.code as depart_code,
	arrive.code as arrive_code,
	depart.time as depart_time,
	arrive.time as arrive_time,
	arrive.time - depart.time as time
from trips
	join stops depart using (trip)
	join stops arrive using (trip)
where
	(depart.type = 'D' or depart.type = 'T') and
	(arrive.type = 'A' or arrive.type = 'T') and
	 depart.stop + 1 = arrive.stop;

alter table links add primary key (trip,depart_code,arrive_code);

drop table if exists links_by_route cascade;
create table links_by_route as select
	route, depart_code, arrive_code,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from links
group by route, depart_code, arrive_code
order by route, depart_code, arrive_code;

alter table links_by_route add primary key (route,depart_code,arrive_code);
