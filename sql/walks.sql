drop table walks cascade;
create table walks as select
	a.code as code_a,
	b.code as code_b,
	coalesce(b.complex = a.complex, false) as same_complex,
	sqrt(power(a.x-b.x,2) + power(a.y-b.y,2)) as euclidean,
	abs(a.x-b.x) + abs(a.y-b.y) as manhattan,
	sqrt(2)*sqrt(power(a.x-b.x,2) + power(a.y-b.y,2)) as pessimistic
from
	stations a,
	stations b;

alter table walks add primary key (code_a,code_b);
