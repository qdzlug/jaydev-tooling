#!/bin/bash

for file in `ls | egrep -v ".gif$"` ; do
convert $file "${file%.*}".gif
mv $file /tmp
done
