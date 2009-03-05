-- minutes in day: 1440
-- maximum considered transfer time: 20
-- largest stop time in stops table: 1664
-- largest replicated transfer time needed: 25 + 1664 = 1689
-- assumed walking rate: (1/8 mile/minute)*(5280 feet/mile) = 660 feet/minute

create temp view stops_with_route as
	select stops.*, route
from stops stops join trips using (trip);

create temp view stops_augmented as select * from (
	select trip, route, stop, code, track, time,        type, tp from stops_with_route union
	select trip, route, stop, code, track, time + 1440, type, tp from stops_with_route
) x where time <= 1689;

create temp table walk_times as select
	arrive_code,
	depart_code,
	pessimistic/660 as walk_time
from walks
where pessimistic/660 <= 20;

alter table walk_times add primary key (arrive_code,depart_code);

create temp table xfers_route_code_pairs as
select distinct
	arrive.route as arrive_route,
	depart.route as depart_route,
	arrive.code  as arrive_code,
	depart.code  as depart_code,
	min(depart.time - arrive.time) as min_xfer,
	max(depart.time - arrive.time) as max_xfer,
from
	walk_times join
	stops_augmented arrive on (arrive.code = arrive_code),
	stops_augmented depart on (depart.code = depart_code)
where
	(arrive.route != depart.route) and
	(arrive.type = 'A' or arrive.type = 'T') and
	(depart.type = 'D' or depart.type = 'T') and
	(depart.time - arrive.time <= 20) and
	(depart.time - arrive.time > 0);

create temp table xfers_min as select
	distinct on (
		arrive.code,
		depart.code,
		arrive.trip,
		depart.route,
		arrive.time
	)
	arrive.code  as arrive_code,
	depart.code  as depart_code,
	arrive.trip  as arrive_trip,
	depart.trip  as depart_trip,
	arrive.time  as arrive_time,
	depart.time  as depart_time
from walk_times
	join stops_augmented arrive on (arrive.code = arrive_code)
	join stops_augmented depart on (depart.code = depart_code)
where
	(arrive.trip != depart.trip) and
	(arrive.type = 'A' or arrive.type = 'T') and
	(depart.type = 'D' or depart.type = 'T') and
	(depart.time - arrive.time > walk_time) and
	(depart.time - arrive.time <= 20)
order by
	arrive.code,
	depart.code,
	arrive.trip,
	depart.route,
	arrive.time,
	depart.time;

select
	count(*)
from
	stops_augmented arrive,
	stops_augmented depart
where
	(arrive.trip != depart.trip) and
	(arrive.type = 'A' or arrive.type = 'T') and
	(depart.type = 'D' or depart.type = 'T') and
	(depart.time - arrive.time <= 20) and
	(depart.time - arrive.time > 0);

create temp table xfers_min as select
	distinct on (
		arrive_trip,
		depart_route,
		arrive_code,
		depart_code
	)
	arrive_trip,
	depart_route,
	arrive_code,
	depart_code,
	depart_time
from
	xfers_all natural join walk_times
where
	depart_time - arrive_time > walk_time
order by
	arrive_trip,
	depart_route,
	arrive_code,
	depart_code,
	depart_time;

create temp table xfers_tmp as select
	arrive_trip,
	trip as depart_trip,
	arrive_code,
	depart_code
from
	xfers_min, stops_augmented
where
	code  = depart_code and
	route = depart_route and
	time  = depart_time;

alter table xfers_tmp add primary key
	(arrive_trip,depart_trip,arrive_code,depart_code);

alter table xfers_tmp add column arrive_route integer;
update xfers_tmp set arrive_route = route from trips where trip = arrive_trip;
alter table xfers_tmp add column depart_route integer;
update xfers_tmp set depart_route = route from trips where trip = depart_trip;

alter table xfers_tmp add column arrive_time real;
update xfers_tmp set arrive_time = time from stops where trip = arrive_trip;
alter table xfers_tmp add column depart_time real;
update xfers_tmp set depart_time = time from stops where trip = depart_trip;
	
alter table xfers_tmp add column xfer_time real;
update xfers_tmp set xfer_time = depart_time - arrive_time;

-- snip --

alter table xfers_tmp add column arrive_time real;
update xfers_tmp set arrive_mod_time =
	case when arrive_time < 1440 then arrive_time else arrive_time - 1440 end;

alter table xfers_tmp add column depart_mod_time real;
update xfers_tmp set depart_mod_time = 
	case when depart_time < 1440 then depart_time else depart_time - 1440 end;

	arrive_time  = time
from trips where trip = arrive_trip;

alter table xfers_tmp add column depart_route integer;
update xfers_tmp set depart_route = route from trips where trip = depart_trip;

drop table if exists xfers cascade;
create table xfers as select
	distinct on (
		arrive_code,
		depart_code,
		arrive_trip,
		depart_trip,
		arrive_mod_time,
		depart_mod_time
	)
	arrive_code,
	depart_code,
	arrive_trip,
	depart_trip,
	arrive_time,
	depart_time,
	xfer_time
from xfers_tmp
order by
	arrive_code,
	depart_code,
	arrive_trip,
	depart_trip,
	arrive_mod_time,
	depart_mod_time,
	arrive_time,
	depart_time;

alter table xfers add primary key
	(arrive_code,depart_code,arrive_trip,depart_trip);

drop table if exists cxfers_by_route cascade;
create table cxfers_by_route as select
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
from cxfers
group by complex, arrive_code, depart_code, arrive_route, depart_route
order by complex, arrive_code, depart_code, arrive_route, depart_route;

alter table cxfers_by_route add primary key
	(complex,arrive_code,depart_code,arrive_route,depart_route);
