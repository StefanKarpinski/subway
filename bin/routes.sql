drop table routes, route_trips, route_codes cascade;

create temp view trip_codes as
	select distinct trip, code
	from stops order by trip, code;

create temp view trip_route_stops as
	select trip, array_to_string(array_accum(code),',') as route_stops
	from trip_codes group by trip;

create temp view trip_dir_routes as
	select trip, direction, route_stops
	from trips natural join trip_route_stops;

create temp sequence route_index_seq;
create temp table routes_tmp as select
	nextval('route_index_seq') as route,
	direction,
	count(*),
	route_stops
from trip_dir_routes
group by route_stops, direction
order by route_stops, direction;

create table route_trips as
	select route, trip
	from trip_route_stops natural join routes_tmp
	order by route, trip;

create index route_trips_route_idx on route_trips (route);
create index route_trips_trip_idx on route_trips (trip);

create table route_codes as
	select distinct route, code
	from route_trips natural join trip_codes
	order by route, code;

create index route_codes_route_idx on route_codes (route);
create index route_codes_trip_idx on route_codes (code);

create table routes as
	select route, direction, count
	from routes_tmp;

create unique index routes_route_idx on routes (route);
