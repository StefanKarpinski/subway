drop table xfers, xfers_aggregate cascade;

create table xfers_reverse 

create table xfers as select
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

create temp view stops_with_route as
	select * from route_trips natural join stops;

create table xfers as
select distinct on (code, trip_in, trip_out, time_in, time_out)
	code,
	i.route as route_in,
	o.route as route_out,
	i.trip as trip_in,
	o.trip as trip_out,
	i.time as time_in,
	o.time as time_out,
	o.time - i.time as time
from
	stops_with_route i join
	stops_with_route o using (code)
where
	i.route <> o.route and
	(i.type = 'A' or i.type = 'T') and
	(o.type = 'D' or o.type = 'T') and
	i.time + 1 < o.time and
	o.time < i.time + 20
order by code, trip_in, trip_out, time_in, time_out;

create table xfers_aggregate as select
	code,
	route_in,
	route_out,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from xfers
group by code, route_in, route_out
order by code, route_in, route_out;
