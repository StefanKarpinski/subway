create temp view stops_with_route as select
	stops.*, route
from trips natural join stops;

create temp table station_xfers_min_times as select
	code,
	i.trip as trip_in,
	i.time as time_in,
	i.route as route_in,
	o.route as route_out,
	min(o.time) as time_out,
	min(o.time) - i.time as min_time
from
	stops_with_route i join
	stops_with_route o using (code)
where
	(i.type = 'A' or i.type = 'T') and
	(o.type = 'D' or o.type = 'T') and
	 i.route <> o.route and
	 o.time - i.time > 0 and
	 o.time - i.time < 20
group by code, trip_in, time_in, route_in, route_out;

drop table station_xfers cascade;
create table station_xfers as select
	code,
	trip_in,
	trip as trip_out,
	route_in,
	route_out,
	time_in,
	time as time_out,
	time - time_in as time
from
	station_xfers_min_times join
	stops_with_route using (code)
where
	route = route_out and
	time = time_out;

drop table station_xfers_aggregate cascade;
create table station_xfers_aggregate as select
	code,
	route_in,
	route_out,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from station_xfers
group by code, route_in, route_out
order by code, route_in, route_out;

create temp view stops_with_complex as select
	stops.*, route, complex
from stations natural join stops join trips using (trip)
where complex is not null;

create temp table complex_xfers_min_times as select
	complex,
	i.code as code_in,
	o.code as code_out,
	i.trip as trip_in,
	i.time as time_in,
	i.route as route_in,
	o.route as route_out,
	min(o.time) as time_out,
	min(o.time) - i.time as min_time
from
	stops_with_complex i join
	stops_with_complex o using (complex)
where
	(i.type = 'A' or i.type = 'T') and
	(o.type = 'D' or o.type = 'T') and
	 i.code <> o.code and
	 o.time - i.time > 0 and
	 o.time - i.time < 20
group by complex, code_in, code_out, trip_in, time_in, route_in, route_out;

drop table complex_xfers cascade;
create table complex_xfers as select
	complex,
	code_in,
	code_out,
	trip_in,
	trip as trip_out,
	route_in,
	route_out,
	time_in,
	time as time_out,
	time - time_in as time
from
	complex_xfers_min_times join
	stops_with_complex using (complex)
where
	route = route_out and
	time = time_out;

drop table complex_xfers_aggregate cascade;
create table complex_xfers_aggregate as select
	complex,
	code_in,
	code_out,
	route_in,
	route_out,
	avg(time) as avg_time,
	stddev_samp(time) as std_time,
	min(time) as min_time,
	max(time) as max_time,
	count(time) as count
from complex_xfers
group by complex, code_in, code_out, route_in, route_out
order by complex, code_in, code_out, route_in, route_out;
