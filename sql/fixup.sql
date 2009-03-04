update stops set code='718' where code='R09';

create temp view used_codes as select distinct code
	from stops natural join stations
	where x is not null and y is not null;

delete from stations where code not in (select code from used_codes);
