#!/bin/bash

url=https://api.github.com
endpoint=/markdown

target=./

## Find all the markdown files

files=$(find ./ -type f -name \*.md)

## Convert them to html

for md in $files; do
  dir=$(dirname $md)
  base=$(basename $md .md)
  out=$target/$dir/${base}.html
  json=${md}.json
  ./generate-json.rb $md
  mkdir -p $target/$dir
  cat ./pre.html > $out
  curl ${url}${endpoint} -s -d @$json >> $out
  cat ./post.html >> $out
  chmod 644 $out
  rm $json
done
