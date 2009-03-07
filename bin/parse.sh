#!/bin/zsh

service=1 # weekdays

perl bin/parse.pl rtif/*/rtif.*..${service}.*

export PGDATABASE=subway
dropdb $PGDATABASE
createdb

cat sql/schema.sql | psql -a

cat data/stations.csv | psql -ac "copy stations from stdin with null as '' csv header"
cat data/trips.tab | psql -ac "copy trips from stdin with null as 'NULL'"
cat data/stops.tab | psql -ac "copy stops from stdin with null as 'NULL'"

for x in \
	fixup \
	complexes \
	walks \
	stops \
	routes \
	dwells \
	links \
	views
do	
	cat sql/$x.sql | psql -a
done
