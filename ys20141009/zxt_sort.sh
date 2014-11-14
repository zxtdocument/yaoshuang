#!/bin/sh
for mdir in AMSU_A AMSU_B HIRS MHS MSU SSU;do
    cd $mdir
    for sdir in *;do
      cd $sdir
         cp ../../newa.sh ./
         chmod 777 newa.sh
         ./newa.sh
      cd ../
    done
    cd ../
done

