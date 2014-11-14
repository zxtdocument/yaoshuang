#!/bin/bash

for f in AMSU_A AMSU_B HIRS MHS MSU SSU;do
    ./sta2.sh  $f >& $f.sta &
done
