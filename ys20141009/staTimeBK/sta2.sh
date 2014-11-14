#!/bin/bash
dir1=$1
find ../$dir1/[^n]* -type f | xargs -n1 -i basename {} > $dir1.log

tmp=`cat $dir1.log | awk -F '.' '{printf("%s.%s.%s\n", $2,$3,$4)}' | sort | uniq`

nameList=""

for name in $tmp;do
    tmp1=${name:0:-3}
    nameList=${nameList}" $tmp1"
done

nameList=`echo $nameList | tr " " "\n" | uniq`
#echo $nameList 

for name in $nameList;do
   begin=`cat $dir1.log | grep -E $name | head -n 1 | awk -F '.' '{printf("%s",$4)}'` 
   end=`cat $dir1.log | grep -E $name | tail -n 1 | awk -F '.' '{printf("%s",$4)}'` 
   echo ${name}.${begin}-${end}
done

