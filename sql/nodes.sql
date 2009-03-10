create type node_type as enum ('arrive','depart');

drop table arrive_nodes cascade;
create table arrive_nodes as select distinct
	arrive_trip as trip,
	arrive_code as code
from xfers;

drop table depart_nodes cascade;
create table depart_nodes as select distinct
	depart_trip as trip,
	depart_code as code
from xfers;

drop table nodes cascade;
create table nodes as select null::integer as index, * from (
	select trip, code, node_type 'arrive' as type from arrive_nodes union
	select trip, code, node_type 'depart' as type from depart_nodes
) x order by trip, code, type;

create temp sequence nodes_seq;
update nodes set index=nextval('nodes_seq');

drop table arrive_nodes_by_route cascade;
create table arrive_nodes_by_route as select distinct
	arrive_route as route,
	arrive_code as code
from xfers_by_route;

drop table depart_nodes_by_route cascade;
create table depart_nodes_by_route as select distinct
	depart_route as route,
	depart_code as code
from xfers_by_route;

drop table nodes_by_route cascade;
create table nodes_by_route as select null::integer as index, * from (
	select route, code, node_type 'arrive' as type from arrive_nodes_by_route union
	select route, code, node_type 'depart' as type from depart_nodes_by_route
) x order by route, code, type;

create temp sequence nodes_by_route_seq;
update nodes_by_route set index=nextval('nodes_by_route_seq');
