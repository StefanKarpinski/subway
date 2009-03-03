create temp view trip_codes as
	select distinct trip, code
	from stops order by trip, code;

create temp view trip_code_lists as
	select trip, array_to_string(array_accum(code),',') as code_list
	from trip_codes group by trip;

create temp view trip_code_list_dirs as
	select trip, code_list, direction
	from trips natural join trip_code_lists;

create temp sequence route_index_seq;
create temp table route_dir_code_lists as select
	nextval('route_index_seq') as route,
	code_list,
	direction
from trip_code_list_dirs
group by code_list, direction
order by code_list, direction;

create temp table route_trips as
	select route, trip
	from route_dir_code_lists natural join trip_code_list_dirs
	order by route, trip;

create unique index route_trips_route_trip_idx on route_trips(route,trip);
create unique index route_trips_trip_idx on route_trips (trip);
create index route_trips_route_idx on route_trips (route);

create temp table route_stops as
	select distinct route, code
	from route_trips natural join trip_codes
	order by route, code;

create unique index route_stops_route_code_idx on route_stops(route,code);
create index route_stops_route_idx on route_stops (route);
create index route_stops_trip_idx on route_stops (code);

drop table routes cascade;
create table routes as select
	route, trip_line, line, direction, orig_code,	dest_code, stops, trips
from route_trips
	natural join trips
	natural join (select route, count(*) as stops from route_stops group by route) sx
	natural join (select route, count(*) as trips from route_trips group by route) tx
group by route, trip_line, line, direction, orig_code,	dest_code, stops, trips
order by
	trip_line,
	line,
	stops desc,
	case when orig_code < dest_code then orig_code else dest_code end,
	case when orig_code > dest_code then orig_code else dest_code end,
	direction,
	trips;

alter table routes add primary key (route);
alter table trips drop column route;
alter table trips add column route integer references routes;
update trips set route = route_trips.route
	from route_trips where trips.trip = route_trips.trip;

create index trips_route_idx on trips (route);

create temp view line_avg_trips as
	select trip_line, avg(trips) as avg_trips
	from routes group by trip_line order by trip_line;

drop table routes_main cascade;
create table routes_main as
	select routes.*
	from routes natural join line_avg_trips
	where trips >= avg_trips;

create unique index routes_main_route_idx on routes_main (route);
