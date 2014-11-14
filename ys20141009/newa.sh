#!/bin/bash
#set -x
dir1="./"
cd $dir1
find ./[^n]* -type f |  while read dir2;do
           dir3=`basename $dir2`
	   echo $dir2
           Name1=`echo $dir3 | awk -F '.' '{printf("%s",$2)}'`
           Name2=`echo $dir3 | awk -F '.' '{printf("%s",$3)}'`
           Name3=`echo $dir3 | awk -F '.' '{printf("%s",$4)}'`
           year=20${Name3:1:2}
           day=$((10#${Name3:3}))

           if [ $[${year} % 4] -eq 0 ] && [ $[${year} % 100] -ne 0 ]; then
               aa=(31 29 31 30 31 30 31 31 30 31 30 31)
           elif [  $[${year} % 400] -eq 0 ]; then
               aa=(31 29 31 30 31 30 31 31 30 31 30 31)
           else
               aa=(31 28 31 30 31 30 31 31 30 31 30 31)
           fi

           if [[ ${day} -le ${aa[0]} ]]; then
                mon=1
           else
               for((i=1;i<=11;i++));do
                  day=`expr ${day} - ${aa[i-1]}`
                  if [[ ${day} -le ${aa[i]} ]]; then
                     mon=`expr $i + 1`
                     break
                  fi
                done
           fi

           if [[ ${mon} -le 9 ]]; then
              mon=0${mon}
           fi
           if [[ ${day} -le 9 ]]; then
              day=0${day}
           fi

           if [[ ! -d ./newdir ]];then
              mkdir ./newdir
           fi

           if [[ ! -d ./newdir/$year ]];then
              mkdir ./newdir/$year
           fi

           if [[ ! -d ./newdir/$year/$mon$day ]];then
               mkdir ./newdir/$year/$mon$day
           fi
 
           if [[ ! -f ./newdir/$year/$mon$day/$dir3 ]];then
              cp $dir2 ./newdir/$year/$mon$day/
           fi
done
