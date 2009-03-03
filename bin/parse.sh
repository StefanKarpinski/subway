#!/bin/zsh

perl bin/parse.pl rtif/*/rtif.*..1.*
cat bin/schema.sql | psql
for x in stations trips stops; do
  cat data/$x.tab | psql -c "copy $x from stdin with null as 'NULL'"
done
cat bin/fixup.sql | psql
