drop table routes cascade;
create table routes as select
	trip_line ||'-'|| direction ||'-'|| dest_code as route,
	trip_line, direction, dest_code
from (
	select distinct trip_line, direction, dest_code from trips
		order by trip_line, direction, dest_code
) x;

alter table routes add primary key (route);
create unique index routes_trip_line_direction_dest_code_idx
	on routes (trip_line,direction,dest_code);

alter table trips drop column route;
alter table trips add column route text references routes;

update trips set route = routes.route
	from routes where
		trips.trip_line = routes.trip_line and
		trips.direction = routes.direction and 
		trips.dest_code = routes.dest_code;

create index trips_route_idx on trips (route);
