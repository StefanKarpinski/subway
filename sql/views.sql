create view station_lines as
	select * from stations
	natural join (
		select code, array_to_string(array_accum(line),',') as lines
		from (
			select distinct code, trip_line as line
			from stations
				join stops using (code)
				join trips using (trip)
		) x
	group by code
) x;
