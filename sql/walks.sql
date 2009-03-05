drop table walks cascade;
create table walks as select
	depart.code as depart_code,
	arrive.code as arrive_code,
	coalesce(depart.complex = arrive.complex, false) as same_complex,
	sqrt(power(arrive.x-depart.x,2) + power(arrive.y-depart.y,2)) as euclidean,
	abs(arrive.x-depart.x) + abs(arrive.y-depart.y) as manhattan,
	sqrt(2)*sqrt(power(arrive.x-depart.x,2) + power(arrive.y-depart.y,2)) as pessimistic
from
	stations depart,
	stations arrive
where
	depart.code != arrive.code;

alter table walks add primary key (depart_code,arrive_code);
