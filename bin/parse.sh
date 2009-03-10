#!/bin/zsh

service=1 # weekdays

perl bin/parse.pl rtif/*/rtif.*..${service}.*

export PGDATABASE=subway
dropdb -e $PGDATABASE
createdb -e

cat sql/schema.sql | psql -a
cat data/stations.csv | psql -ac "copy stations from stdin with null as '' csv header"
cat data/trips.tab | psql -ac "copy trips from stdin with null as 'NULL'"
cat data/stops.tab | psql -ac "copy stops from stdin with null as 'NULL'"

cat sql/fixup.sql  | psql -a
cat sql/walks.sql  | psql -a
cat sql/stops.sql  | psql -a
cat sql/routes.sql | psql -a
cat sql/links.sql  | psql -a
cat sql/views.sql  | psql -a

psql -ac "truncate table xfers"
bin/xfers.pl | bzip2 -9 > data/xfers.csv.bz2
bzcat data/xfers.csv.bz2 | bin/batch.pl psql -ac "copy xfers from stdin csv"
cat sql/xfers.sql | psql -a
