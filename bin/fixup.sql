delete from trips where service <> 1;

create view stop_codes as
	select distinct code from stops where stop;

create view real_stations as
	select * from stations natural join stop_codes
	where x is not null and y is not null;

update stops set code='718' where code='R09';
delete from stations where code not in (select code from real_stations);
drop view stop_codes cascade;

delete from stops where not stop;
alter table stops drop column stop;
