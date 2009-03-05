#!/bin/zsh

service=1

perl bin/parse.pl rtif/*/rtif.*..${service}.*

export PGDATABASE=subway
dropdb $PGDATABASE
createdb
cat sql/schema.sql | psql -a

for x in stations trips stops; do
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
	sxfers \
	cxfers \
	views
do	
	cat sql/$x.sql | psql -a
done
