create index xfers_routes_codes_idx on xfers
	(arrive_route,depart_route,arrive_code,depart_code);

drop table if exists xfers_by_route cascade;
create table xfers_by_route as select
	arrive_route,
	depart_route,
	arrive_code,
	depart_code,
	type,
	avg(time) as avg_time,
	stddev_samp(time) as stddev,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from xfers
group by
	arrive_route,
	depart_route,
	arrive_code,
	depart_code,
	type
order by
	arrive_route,
	depart_route,
	arrive_code,
	depart_code,
	type;

alter table xfers_by_route add primary key
	(arrive_route,depart_route,arrive_code,depart_code);
