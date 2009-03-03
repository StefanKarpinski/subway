drop table stops_indexed cascade;

create temp sequence stops_index_seq;
create table stops_indexed as
	select nextval('stops_index_seq') as index, *
	from stops order by trip, time;
