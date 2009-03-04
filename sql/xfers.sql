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
	arrive.trip as arrive_trip,
	arrive.route as arrive_route,
	depart.route as depart_route,
	arrive.time as arrive_time,
	min(depart.time) as depart_time,
	min(depart.time) - arrive.time as min_xfer
from
	stops_with_route arrive join
	stops_with_route depart using (code)
where
	(arrive.type = 'A' or arrive.type = 'T') and
	(depart.type = 'D' or depart.type = 'T') and
	 arrive.route <> depart.route and
	 depart.time - arrive.time > 0 and
	 depart.time - arrive.time <= 25
group by code, arrive_trip, arrive_time, arrive_route, depart_route;

create temp table station_xfers_tmp as select
	code,
	arrive_trip,
	trip as depart_trip,
	arrive_route,
	depart_route,
	arrive_time,
	depart_time,
	case when arrive_time < 1440 then arrive_time else arrive_time - 1440 end as arrive_mod_time,
	case when depart_time < 1440 then depart_time else depart_time - 1440 end as depart_mod_time,
	min_xfer as xfer_time
from
	station_min_xfers join
	stops_with_route using (code)
where
	route = depart_route and
	time = depart_time;

drop table if exists station_xfers cascade;
create table station_xfers as select
	distinct on (
		code,
		arrive_trip,
		depart_trip,
		arrive_mod_time,
		depart_mod_time
	)
	code,
	arrive_trip,
	depart_trip,
	arrive_route,
	depart_route,
	arrive_time,
	depart_time,
	xfer_time
from station_xfers_tmp
order by
	code,
	arrive_trip,
	depart_trip,
	arrive_mod_time,
	depart_mod_time,
	arrive_time,
	depart_time;

alter table station_xfers add primary key (code,arrive_trip,depart_trip);

drop table if exists station_xfers_aggregate cascade;
create table station_xfers_aggregate as select
	code,
	arrive_route,
	depart_route,
	avg(xfer_time) as avg_xfer,
	stddev_samp(xfer_time) as stddev,
	min(xfer_time) as min_xfer,
	max(xfer_time) as max_xfer,
	count(xfer_time) as count
from station_xfers
group by code, arrive_route, depart_route
order by code, arrive_route, depart_route;

alter table station_xfers_aggregate add primary key (code,arrive_route,depart_route);

create temp view stops_with_complex as select
	stops.*, route, complex
from stops_augmented stops
	join trips using (trip)
	join stations using (code)
where complex is not null;

create temp table complex_min_xfers as select
	complex,
	arrive.code as arrive_code,
	depart.code as depart_code,
	arrive.trip as arrive_trip,
	arrive.route as arrive_route,
	depart.route as depart_route,
	arrive.time as arrive_time,
	min(depart.time) as depart_time,
	min(depart.time) - arrive.time as min_xfer
from
	stops_with_complex arrive join
	stops_with_complex depart using (complex)
where
	(arrive.type = 'A' or arrive.type = 'T') and
	(depart.type = 'D' or depart.type = 'T') and
	 arrive.code <> depart.code and
	 depart.time - arrive.time >= 2 and
	 depart.time - arrive.time <= 25
group by complex, arrive_code, depart_code, arrive_trip, arrive_time, arrive_route, depart_route;

create temp table complex_xfers_tmp as select
	complex,
	arrive_code,
	depart_code,
	arrive_trip,
	trip as depart_trip,
	arrive_route,
	depart_route,
	arrive_time,
	depart_time,
	case when arrive_time < 1440 then arrive_time else arrive_time - 1440 end as arrive_mod_time,
	case when depart_time < 1440 then depart_time else depart_time - 1440 end as depart_mod_time,
	min_xfer as xfer_time
from
	complex_min_xfers join
	stops_with_complex using (complex)
where
	route = depart_route and
	time = depart_time;

drop table if exists complex_xfers cascade;
create table complex_xfers as select
	distinct on (
		complex,
		arrive_code,
		depart_code,
		arrive_trip,
		depart_trip,
		arrive_mod_time,
		depart_mod_time
	)
	complex,
	arrive_code,
	depart_code,
	arrive_trip,
	depart_trip,
	arrive_route,
	depart_route,
	arrive_time,
	depart_time,
	xfer_time
from complex_xfers_tmp
order by
	complex,
	arrive_code,
	depart_code,
	arrive_trip,
	depart_trip,
	arrive_mod_time,
	depart_mod_time,
	arrive_time,
	depart_time;

alter table complex_xfers add primary key
	(complex,arrive_code,depart_code,arrive_trip,depart_trip);

drop table if exists complex_xfers_aggregate cascade;
create table complex_xfers_aggregate as select
	complex,
	arrive_code,
	depart_code,
	arrive_route,
	depart_route,
	avg(xfer_time) as avg_xfer,
	stddev_samp(xfer_time) as stddev,
	min(xfer_time) as min_xfer,
	max(xfer_time) as max_xfer,
	count(xfer_time) as count
from complex_xfers
group by complex, arrive_code, depart_code, arrive_route, depart_route
order by complex, arrive_code, depart_code, arrive_route, depart_route;

alter table complex_xfers_aggregate add primary key
	(complex,arrive_code,depart_code,arrive_route,depart_route);
