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
