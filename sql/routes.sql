create temp sequence route_seq;
create table routes as select
	nextval('route_seq') as route,
	trip_line, direction, dest_code
from trips group by trip_line, direction, dest_code;

alter table routes add primary key (route);
alter table trips drop column route;
alter table trips add column route integer references routes;

update trips set route = routes.route
	from routes where
		trips.trip_line = routes.trip_line and
		trips.direction = routes.direction and 
		trips.dest_code = routes.dest_code;

create index trips_route_idx on trips (route);
