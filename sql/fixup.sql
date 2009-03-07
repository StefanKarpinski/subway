-- patch stop entries using alternate station codes --

update stops set code=stations.code
	from stations where stops.code=stations.alt;

alter table stops add foreign key (code)
	references stations on delete cascade;

-- generate fake AQR stop data --

insert into stops select
	trip,
	'AQR' as code,
	'01' as track,
	time+1 as time,
	type,
	tp
from trips join stops using (trip)
where
	direction='N' and code='H02' and
	11*60 <= time and time <= 19*60;
