#!/bin/zsh

service=1 # weekdays

perl bin/parse.pl rtif/*/rtif.*..${service}.*

export PGDATABASE=subway
dropdb $PGDATABASE
createdb

cat sql/schema.sql | psql -a
cat data/stations.csv | \
	psql -ac "copy stations from stdin with null as '' csv header"

for x in trips stops; do
  cat data/$x.tab | psql -ac "copy $x from stdin with null as 'NULL'"
done

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
