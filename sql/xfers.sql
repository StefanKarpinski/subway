create type xfer_type as enum (
	'dwell',
	'station',
	'complex',
	'tunnel',
	'external'
);

drop table xfers cascade;
create table xfers (
	arrive_trip text references trips,
	depart_trip text references trips,
	arrive_route text references routes,
	depart_route text references routes,
	arrive_code text references stations,
	depart_code text references stations,
	type xfer_type,
	time real,
	primary key (arrive_trip,depart_trip,arrive_code,depart_code)
);
