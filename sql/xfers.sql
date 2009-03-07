create type xfer_type as enum (
	'dwell',
	'station',
	'complex',
	'tunnel',
	'external'
);

drop table xfers cascade;
create table xfers (
	arrive_route integer references routes,
	depart_route integer references routes,
	arrive_trip integer references trips,
	depart_trip integer references trips,
	arrive_code text references stations,
	depart_code text references stations,
	type xfer_type,
	time real,
	primary key (arrive_trip,depart_trip,arrive_code,depart_code)
);
