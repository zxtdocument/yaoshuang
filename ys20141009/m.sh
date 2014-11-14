#!/bin/bash
year=$1 
day1=$2;day2=$3

if [ $[${year} % 4] -eq 0 ] && [ $[${year} % 100] -ne 0 ]; then
     aa=(31 29 31 30 31 30 31 31 30 31 30 31) 
 elif [  $[${year} % 400] -eq 0 ]; then
     aa=(31 29 31 30 31 30 31 31 30 31 30 31) 
 else
     aa=(31 28 31 30 31 30 31 31 30 31 30 31) 
 fi  

 if [[ ${day1} -le ${aa[0]} ]]; then
      mon1=1
 else
     for((i=1;i<=11;i++));do
        day1=`expr ${day1} - ${aa[i-1]}`
        if [[ ${day1} -le ${aa[i]} ]]; then
           mon1=`expr $i + 1`
           break
        fi  
      done
 fi  

 if [[ ${day2} -le ${aa[0]} ]]; then
      mon2=1
 else
     for((i=1;i<=11;i++));do
        day2=`expr ${day2} - ${aa[i-1]}`
        if [[ ${day2} -le ${aa[i]} ]]; then
           mon2=`expr $i + 1`
           break
        fi  
      done
 fi  

echo "$year-$mon1-$day1    $year-$mon2-$day2"
