-- minutes in day: 1440
-- maximum considered transfer time: 25
-- largest stop time in stops table: 1664
-- largest replicated transfer time needed: 25 + 1664 = 1689

create temp view stops_augmented as select * from (
	select trip, stop, code, track, time, type, tp from stops union
	select trip, stop, code, track, 1440 + time, type, tp from stops
) x where time <= 1689;

create temp view stops_with_route as select
	stops.*, route
from stops_augmented stops
	join trips using (trip);

create temp table station_min_xfers as select
	code,
	i.trip as trip_in,
	i.route as route_in,
	o.route as route_out,
	i.time as time_in,
	min(o.time) as time_out,
	min(o.time) - i.time as min_xfer
from
	stops_with_route i join
	stops_with_route o using (code)
where
	(i.type = 'A' or i.type = 'T') and
	(o.type = 'D' or o.type = 'T') and
	 i.route <> o.route and
	 o.time - i.time > 0 and
	 o.time - i.time <= 25
group by code, trip_in, time_in, route_in, route_out;

create temp table station_xfers_tmp as select
	code,
	trip_in,
	trip as trip_out,
	route_in,
	route_out,
	time_in,
	time_out,
	case when time_in < 1440 then time_in else time_in - 1440 end as mod_time_in,
	case when time_out < 1440 then time_out else time_out - 1440 end as mod_time_out,
	min_xfer as xfer_time
from
	station_min_xfers join
	stops_with_route using (code)
where
	route = route_out and
	time = time_out;

drop table if exists station_xfers cascade;
create table station_xfers as select
	distinct on (
		code,
		trip_in,
		trip_out,
		mod_time_in,
		mod_time_out
	)
	code,
	trip_in,
	trip_out,
	route_in,
	route_out,
	time_in,
	time_out,
	xfer_time
from station_xfers_tmp
order by
	code,
	trip_in,
	trip_out,
	mod_time_in,
	mod_time_out,
	time_in,
	time_out;

alter table station_xfers add primary key (code,trip_in,trip_out);

drop table if exists station_xfers_aggregate cascade;
create table station_xfers_aggregate as select
	code,
	route_in,
	route_out,
	avg(xfer_time) as avg_xfer,
	stddev_samp(xfer_time) as stddev,
	min(xfer_time) as min_xfer,
	max(xfer_time) as max_xfer,
	count(xfer_time) as count
from station_xfers
group by code, route_in, route_out
order by code, route_in, route_out;

alter table station_xfers_aggregate add primary key (code,route_in,route_out);

create temp view stops_with_complex as select
	stops.*, route, complex
from stops_augmented stops
	join trips using (trip)
	join stations using (code)
where complex is not null;

create temp table complex_min_xfers as select
	complex,
	i.code as code_in,
	o.code as code_out,
	i.trip as trip_in,
	i.route as route_in,
	o.route as route_out,
	i.time as time_in,
	min(o.time) as time_out,
	min(o.time) - i.time as min_xfer
from
	stops_with_complex i join
	stops_with_complex o using (complex)
where
	(i.type = 'A' or i.type = 'T') and
	(o.type = 'D' or o.type = 'T') and
	 i.code <> o.code and
	 o.time - i.time > 2 and
	 o.time - i.time <= 25
group by complex, code_in, code_out, trip_in, time_in, route_in, route_out;

create temp table complex_xfers_tmp as select
	complex,
	code_in,
	code_out,
	trip_in,
	trip as trip_out,
	route_in,
	route_out,
	time_in,
	time_out,
	case when time_in < 1440 then time_in else time_in - 1440 end as mod_time_in,
	case when time_out < 1440 then time_out else time_out - 1440 end as mod_time_out,
	min_xfer as xfer_time
from
	complex_min_xfers join
	stops_with_complex using (complex)
where
	route = route_out and
	time = time_out;

drop table if exists complex_xfers cascade;
create table complex_xfers as select
	distinct on (
		complex,
		code_in,
		code_out,
		trip_in,
		trip_out,
		mod_time_in,
		mod_time_out
	)
	complex,
	code_in,
	code_out,
	trip_in,
	trip_out,
	route_in,
	route_out,
	time_in,
	time_out,
	xfer_time
from complex_xfers_tmp
order by
	complex,
	code_in,
	code_out,
	trip_in,
	trip_out,
	mod_time_in,
	mod_time_out,
	time_in,
	time_out;

alter table complex_xfers add primary key
	(complex,code_in,code_out,trip_in,trip_out);

drop table if exists complex_xfers_aggregate cascade;
create table complex_xfers_aggregate as select
	complex,
	code_in,
	code_out,
	route_in,
	route_out,
	avg(xfer_time) as avg_xfer,
	stddev_samp(xfer_time) as stddev,
	min(xfer_time) as min_xfer,
	max(xfer_time) as max_xfer,
	count(xfer_time) as count
from complex_xfers
group by complex, code_in, code_out, route_in, route_out
order by complex, code_in, code_out, route_in, route_out;

alter table complex_xfers_aggregate add primary key
	(complex,code_in,code_out,route_in,route_out);
