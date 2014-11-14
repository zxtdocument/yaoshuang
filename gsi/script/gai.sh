#!/bin/bash
for f in *.sh;do
  sed 's%/u/yaosh%/u/yaosh%g' $f > ../script/$f
done
