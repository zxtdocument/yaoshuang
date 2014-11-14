#!/bin/bash
sta() {
    awk '{if($1>85000){printf("A ");}if($1<=85000 && $1>50000){printf("B ");}if($1<=50000 && $1>30000){printf("C ");}if($1<=30000 && $1>10000){printf("D ");}if($1<=10000){printf("E ")}printf("%s %s %s\n",$2,$3,$4)}' $1 > u2.txt
    
    cat u2.txt | grep ^A | awk '{printf("%s %s %s\n",$2,$3,$4)}' | sort > uA.txt
    cat u2.txt | grep ^B | awk '{printf("%s %s %s\n",$2,$3,$4)}' | sort > uB.txt
    cat u2.txt | grep ^C | awk '{printf("%s %s %s\n",$2,$3,$4)}' | sort > uC.txt
    cat u2.txt | grep ^D | awk '{printf("%s %s %s\n",$2,$3,$4)}' | sort > uD.txt
    cat u2.txt | grep ^E | awk '{printf("%s %s %s\n",$2,$3,$4)}' | sort > uE.txt
    
    echo '>850hPa' >>A.tmp
    for site in `cat siteID.txt`;do
        Anum=`cat uA.txt | grep ^$site | wc -l`
        siteInfo=`cat siteInfo.txt | grep ^$site`
        echo $siteInfo $Anum >>A.tmp
    done
    
    echo '850-500hPa' >>B.tmp
    for site in `cat siteID.txt`;do
        Bnum=`cat uB.txt | grep ^$site | wc -l`
        siteInfo=`cat siteInfo.txt | grep ^$site`
        echo $siteInfo $Bnum >>B.tmp
    done
    
    echo '500-300hPa' >>C.tmp
    for site in `cat siteID.txt`;do
        Cnum=`cat uC.txt | grep ^$site | wc -l`
        siteInfo=`cat siteInfo.txt | grep ^$site`
        echo $siteInfo $Cnum >>C.tmp
    done
    
    echo '300-100hPa' >>D.tmp
    for site in `cat siteID.txt`;do
        Dnum=`cat uD.txt | grep ^$site | wc -l`
        siteInfo=`cat siteInfo.txt | grep ^$site`
        echo $siteInfo $Dnum >>D.tmp
    done
    
    echo '<100hPa' >>E.tmp
    for site in `cat siteID.txt`;do
        Enum=`cat uE.txt | grep ^$site | wc -l`
        siteInfo=`cat siteInfo.txt | grep ^$site`
        echo $siteInfo $Enum >>E.tmp
    done

    paste A.tmp B.tmp C.tmp D.tmp E.tmp > $2

    rm -rvf uA.txt uB.txt uC.txt uD.txt uE.txt *.tmp u2.txt
}

awk '{if($2>100000 && $8==0){printf("%s %d %s %s\n",$5,$2%100000,$3,$4)}}'  gts_omb_oma.conv >u.txt
sta u.txt uS.txt

awk '{if($2>100000 && $13==0){printf("%s %d %s %s\n",$5,$2%100000,$3,$4)}}'  gts_omb_oma.conv >v.txt
sta v.txt vS.txt

awk '{if($2>100000 && $18==0){printf("%s %d %s %s\n",$5,$2%100000,$3,$4)}}'  gts_omb_oma.conv >t.txt
sta t.txt tS.txt

awk '{if($2>100000 && $23==0){printf("%s %d %s %s\n",$5,$2%100000,$3,$4)}}'  gts_omb_oma.conv >q.txt
sta q.txt qS.txt

rm -rvf u.txt v.txt t.txt q.txt
