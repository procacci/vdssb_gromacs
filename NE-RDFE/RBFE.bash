
#!/bin/bash

if [ ! -d Datarel -o $# -eq 0 ] ; then 
    echo " Extract work data from [bu]xxxx  dirs and compute relative free energies" 
    echo " for the transformation of noghost into ghost                      " 
    echo " syntax: ../bin/RBFE.bash [opt] ghost noghost"
    echo " ghost and noghost are the compound names of the molecule A (ghost)"
    echo " to be transformed into B (noghost)"
    echo " Options: "
    echo "        -u timeu" 
    echo "          arg 'timeu' specify the duration time for the unbound state"
    echo "        -b timeb" 
    echo "          arg 'timeb' specify the duration time for the bound state"
    echo "        -f " 
    echo "          do only free energy calculations without extracting the workfiles (work files MUST be on Datarel directory) " 
    echo "        -x out_threshold" 
    echo "          arg 'out_threshold' specify threshold (in sigmas) for outliers in work data; Default is 3.3" 
    echo "        -s sign" 
    echo "          arg 'sign' specify the the sign to be used in the work calculation from the dhdl file" 
    echo "        -D dir" 
    echo "          use dir instead of Datarel for work data "
    echo ""
    echo " N.B: give this command from the github main dir"
    if [ ! -d Datarel ]; then
	mkdir Datarel
    else
	exit
    fi
fi 


uw=0
bw=0
free=0
ignore=0
dirdata="Datarel"
tb=720
s=1
tu=360
xs=3.3
while getopts ":u:b:x:s:foiD:" opt; do 
    case $opt in 
	u)
	    uw=1
	    tu=$OPTARG
	    ;;
	b)
	    bw=1
	    tb=$OPTARG
	    ;;
	x)
	    xs=$OPTARG
	    ;;
	s)
	    s=$OPTARG
	    ;;
	f) 
	    free=1
	    ;;
	D)
	    dirdata=$OPTARG
	    ;;
    esac
done
echo "Dir="$dirdata " Sign="$s " Time_u="$tu " Time_b="$tb " xs ="$xs

A=${!#}                                        # noghost
B=`echo "${@: -2}" | awk '{print $1}'`         # ghost 

if [ -z $A -o -z $B ]; then
    echo " syntax: RBFE.bash [opt] ghost noghost"
    exit
fi

zscore="zscore_rec.awk -v xs=$xs"

#### FUNCTION DG BEGINS HERE : this code assumes that the wrk files have been generated and evaluates the RBFE as the difference DG_rel=(A-B)_bound-(A-B)_solv
function rbfe {
    printf "${A}->${B}  "
#   BOUND
    for i in b u ; do 
	if [ $i == "b" ] ; then t=$tb ; fi
	if [ $i == "u" ] ; then t=$tu ; fi
	if [ -f ${A}-${B}_${i}_$t.wrk -a ${B}-${A}_${i}_$t.wrk ]; then 
	    $zscore ${A}-${B}_${i}_$t.wrk | grep -v "#" > $A.$B.$i.$t.wrk
	    $zscore ${B}-${A}_${i}_$t.wrk | grep -v "#" > $B.$A.$i.$t.wrk
	    Free_bs.bash $A.$B.$i.$t.wrk  > DG${A}-${B}_${i}_$t
	    Free_bs.bash $B.$A.$i.$t.wrk  > DG${B}-${A}_${i}_$t
	    awk '{print  $1/4.184}' $A.$B.$i.$t.wrk | histog +i0.5  > ${A}-${B}_${i}_$t.hst
	    awk '{print -$1/4.184}' $B.$A.$i.$t.wrk | histog +i0.5  > ${B}-${A}_${i}_$t.hst
	    sig_AB=`kurt+skew.bash $A.$B.$i.$t.wrk | awk '{print sqrt($4)}'`
	    ADT_AB=`qq $A.$B.$i.$t.wrk  | grep Anders | awk '{print $8}'` 
	    echo $sig_AB > SAB.$i
	    echo $ADT_AB > AAB.$i
	    sig_BA=`kurt+skew.bash $B.$A.$i.$t.wrk | awk '{print sqrt($4)}'`
	    ADT_BA=`qq $B.$A.$i.$t.wrk  | grep Anders | awk '{print $8}'` 
	    echo $sig_BA > SBA.$i
	    echo $ADT_BA > ABA.$i
	    rm DG.tmp.$i >& /dev/null
	    for j in {1..40}; do 
		bs_res.awk -v seed=$j $A.$B.$i.$t.wrk > works_forward 
		bs_res.awk -v seed=$j $B.$A.$i.$t.wrk > works_reverse 
		bennett | awk '{print $7}' >> DG.tmp.$i
	    done
	    awk '{a+=$1; a2+=$1^2}END{printf "%8.2f%8.2f\n", a/NR/4.184,1.96*sqrt(a2/NR -(a/NR)^2)/4.184}' DG.tmp.$i > DG${A}-${B}_${i}_${t}_BAR
	elif [ -f ${A}-${B}_${i}_$t.wrk ]; then 
	    $zscore ${A}-${B}_${i}_$t.wrk | grep -v "#" > $A.$B.$i.$t.wrk
	    awk '{print  $1/4.184}' $A.$B.$i.$t.wrk | histog +i0.5  > ${A}-${B}_${i}_$t.hst
	    Free_bs.bash $A.$B.$i.$t.wrk  > DG${A}-${B}_${i}_$t
	    sig_AB=`kurt+skew.bash $A.$B.$i.$t.wrk | awk '{print sqrt($4)}'`
	    ADT_AB=`qq $A.$B.$i.$t.wrk  | grep Anders | awk '{print $8}'` 
	    echo $sig_AB > SAB.$i
	    echo $ADT_AB > AAB.$i
	elif [ -f ${B}-${A}_${i}_$t.wrk ]; then 
	    $zscore ${B}-${A}_${i}_$t.wrk | grep -v "#" > $B.$A.$i.$t.wrk
	    awk '{print  $1/4.184}' $B.$A.$i.$t.wrk | histog +i0.5  > ${B}-${A}_${i}_$t.hst
	    Free_bs.bash $B.$A.$i.$t.wrk  > DG${B}-${A}_${i}_$t
	    sig_BA=`kurt+skew.bash $B.$A.$i.$t.wrk | awk '{print sqrt($4)}'`
	    ADT_BA=`qq $B.$A.$i.$t.wrk  | grep Anders | awk '{print $8}'` 
	    echo $sig_BA > SBA.$i
	    echo $ADT_BA > ABA.$i
	fi
    done

    # bar 
    if [ -s DG${A}-${B}_b_${tb}_BAR -a -s DG${A}-${B}_u_${tu}_BAR ] ; then
	paste DG${A}-${B}_b_${tb}_BAR DG${A}-${B}_u_${tu}_BAR \
	| awk '{printf " DG_bar= %7.2f%7.2f ",$1-$3,sqrt($2^2+$4^2)}'
    fi
    # ff 
    if [ -s DG${A}-${B}_b_$tb -a -s DG${A}-${B}_u_$tu ] ; then
	paste DG${A}-${B}_b_$tb DG${A}-${B}_u_$tu \
	| awk '{printf " DG_ff_G= %6.1f%6.1f ",$2-$7,sqrt($3^2+$8^2)}'
	paste DG${A}-${B}_b_$tb DG${A}-${B}_u_$tu \
	| awk '{printf " DG_ff_J= %6.1f%6.1f ",$4-$9,sqrt($5^2+$10^2)}'
	printf " sig_AB_u= %5.2f" `cat SAB.u` 
	printf " sig_AB_b= %5.2f" `cat SAB.b` 
	printf " ADT_AB_u= %5.2f" `cat AAB.u`
	printf " ADT_AB_b= %5.2f" `cat AAB.b`
    fi
    # rr 
    if [ -s DG${B}-${A}_b_$tb -a -s DG${B}-${A}_u_$tu ] ; then
	paste DG${B}-${A}_b_$tb DG${B}-${A}_u_$tu\
	| awk '{printf " DG_rr_G= %6.1f%6.1f ",$7-$2,sqrt($3^2+$8^2)}'
	paste DG${B}-${A}_b_$tb DG${B}-${A}_u_$tu\
	| awk '{printf " DG_rr_J= %6.1f%6.1f ",$9-$4,sqrt($5^2+$10^2)}'
	printf " sig_BA_u= %5.2f" `cat SBA.u` 
	printf " sig_BA_b= %5.2f" `cat SBA.b` 
	printf " ADT_BA_u= %5.2f" `cat ABA.u`
	printf " ADT_BA_b= %5.2f" `cat ABA.b`
    fi
    # now check for vdssb
    if [ -s DG${A}-${B}_b_$tb -a -s DG${B}-${A}_u_$tu ] ; then
	wab=$A.$B.b.$tb.wrk
	wba=$B.$A.u.$tu.wrk
	nab=`wc -l $wab | awk '{print $1}'` 
	nba=`wc -l $wba | awk '{print $1}'` 
	rm GJ.tmp >&/dev/null
	# bootstrap loop
	for i in {1..10} ; do
	    bs_res.awk -v seed=$i $wab > ab.tmp
	    bs_res.awk -v seed=$i $wba > ba.tmp
	    cat ab.tmp ba.tmp  > file.tmp  # combine bootstrapped files
	    awk -v nab=$nab -v nba=$nba '\
            {\
             if(NR<=nab)  {wab[NR]=$1} else {wba[NR-nab]=$1}\
            }\
            END{\
                for(i=1; i<=nab; i++) {\
                    for(j=1; j<=nba; j++){\
                       print  wab[i]+wba[j]\
                    }\
                }\
          }'	 file.tmp > vdssb.tmp
	    free.awk vdssb.tmp | awk '{print $5,$6}' >>  GJ.tmp
	done
	# store full vDSSB work
	cat $wab $wba > file.tmp 
	awk -v nab=$nab -v nba=$nba '\
            {\
             if(NR<=nab)  {wab[NR]=$1} else {wba[NR-nab]=$1}\
            }\
            END{\
                for(i=1; i<=nab; i++) {\
                    for(j=1; j<=nba; j++){\
                       print  wab[i]+wba[j]\
                    }\
                }\
          }'	 file.tmp > $A.$B.$tb.$tu.vDSSB.wrk
    fi
    awk '{a+=$1;a2+=$1^2}END{printf "  DG_fr_G= %6.2f%6.2f",a/NR-bias,1.96*sqrt(a2/NR-(a/NR)^2)}' GJ.tmp
    # find theoretical bias
    npt=`wc -l $A.$B.$tb.$tu.vDSSB.wrk  | awk '{print $1}'`
    sigma=`free.awk $A.$B.$tb.$tu.vDSSB.wrk | awk '{print sqrt($2)}'`
    gob=`paste AAB.b ABA.u SAB.b SBA.u | awk '{a=0.5*($1+$2); s=sqrt($3^2+$4^2); if (a < 0.7 && a < 3.5)  {print 1}else {print 0}}'  `
    if [ $gob == 1 ] ; then
	bias=`find_bias.bash $sigma $npt | awk '{print $1}'`
    else
	bias=0
    fi
    awk -v bias=$bias '{a+=$2;a2+=$2^2}END{printf "  DG_fr_J= %6.2f%6.2f",a/NR-bias,1.96*sqrt(a2/NR-(a/NR)^2)}' GJ.tmp
    printf " bias_fr= %4.1f" $bias 
    rm JG.tmp >& /dev/null
    if [ -s DG${B}-${A}_b_$tb -a -s DG${A}-${B}_u_$tu ] ; then
	wab=$B.$A.b.$tb.wrk
	wba=$A.$B.u.$tu.wrk
	nab=`wc -l $wab | awk '{print $1}'` 
	nba=`wc -l $wba | awk '{print $1}'` 
	rm jar.tmp >&/dev/null
	# bootstrap loop
	for i in {1..10} ; do
	    bs_res.awk -v seed=$i $wab > ab.tmp
	    bs_res.awk -v seed=$i $wba > ba.tmp
	    cat ab.tmp ba.tmp  > file.tmp  # combine bootstrapped files
	    awk -v nab=$nab -v nba=$nba '\
            {\
             if(NR<=nab)  {wab[NR]=$1} else {wba[NR-nab]=$1}\
            }\
            END{\
                for(i=1; i<=nab; i++) {\
                    for(j=1; j<=nba; j++){\
                       print  wab[i]+wba[j]\
                    }\
                }\
          }'	 file.tmp > vdssb.tmp
	    free.awk vdssb.tmp | awk '{print $5,$6}' >>  JG.tmp
	done
	# store full vDSSB work
	cat $wab $wba > file.tmp 
	awk -v nab=$nab -v nba=$nba '\
            {\
             if(NR<=nab)  {wab[NR]=$1} else {wba[NR-nab]=$1}\
            }\
            END{\
                for(i=1; i<=nab; i++) {\
                    for(j=1; j<=nba; j++){\
                       print  wab[i]+wba[j]\
                    }\
                }\
          }'	 file.tmp > $B.$A.$tb.$tu.vDSSB.wrk
    fi
    awk '{a+=$1;a2+=$1^2}END{printf "  DG_rf_G= %6.2f%6.2f",-a/NR-bias,1.96*sqrt(a2/NR-(a/NR)^2)}' JG.tmp
    # find theoretical bias
    npt=`wc -l $B.$A.$tb.$tu.vDSSB.wrk  | awk '{print $1}'`
    sigma=`free.awk $B.$A.$tb.$tu.vDSSB.wrk | awk '{print sqrt($2)}'`
    gob=`paste ABA.b AAB.u SBA.b SAB.u | awk '{a=0.5*($1+$2); s=sqrt($3^2+$4^2); if (a < 0.7 && a < 3.5)  {print 1}else {print 0}}'  `
    if [ $gob == 1 ] ; then
	bias=`find_bias.bash $sigma $npt | awk '{print $1}'`
    else
	bias=0
    fi
    awk -v bias=$bias '{a+=$2;a2+=$2^2}END{printf "  DG_rf_J= %6.2f%6.2f",-a/NR-bias,1.96*sqrt(a2/NR-(a/NR)^2)}' JG.tmp
    printf " bias_rf= %4.1f" $bias 

    cp $A.$B.$tb.$tu.vDSSB.wrk works_forward
    cp $B.$A.$tb.$tu.vDSSB.wrk works_reverse
    bennett | awk '{printf " DG_BAR= %6.2f 0.0",$7/4.184}' 

    awk '{print $1/4.184}' $A.$B.$tb.$tu.vDSSB.wrk | histog +i0.2  > $A.$B.$tb.$tu.vDSSB.hst
    awk '{print $1/4.184}' $B.$A.$tb.$tu.vDSSB.wrk | histog +i0.2  > $B.$A.$tb.$tu.vDSSB.hst
    
    printf " tb= %4d" $tb
    printf " tu= %4d" $tu
    printf "\n"
}


# Compute free energy without processing work files
if [ $free = 1 ]; then
    if [ -d $dirdata ]; then
	cd $dirdata
	rbfe
	exit
    else
	echo "no $dirdata found"
	exit
    fi
fi

dhdl="dhdl.xvg"

rm $dirdata/${A}-${B}_b_$tb.wrk >& /dev/null
rm $dirdata/${B}-${A}_b_$tb.wrk >& /dev/null
 
if [ $bw == 1 ] ; then 
    echo "Doing bound state ... " $A "->" $B
    if  [ -d b-${A}-${B} ] ; then
	cd b-${A}-${B}
	for i in b[0-9]*; do
	    cd $i ;
	    if [ -f $dhdl ]; then 
		dl=`grep -v -e "[#@]" $dhdl | wc -l | awk '{print dl=1/($1-1)}'`
		grep -v -e "[#@]" $dhdl | awk -v dl=$dl -v s=$s '{a+=$2*dl; print $1,s*a}' > file.wrk
		tail -1 file.wrk | awk '{print $2}'>> ../../$dirdata/${A}-${B}_b_$tb.wrk
	    else
		echo "no dhdl file in b-${B}-${A}/$i directory"
	    fi
	    cd ../
	done
	cd ../
    fi
    echo "Doing bound state... " $B "->" $A 
    if  [ -d b-${B}-${A} ] ; then
	cd b-${B}-${A}
	for i in b[0-9]*; do
	    cd $i ;
	    if [ -f $dhdl ]; then 
		dl=`grep -v -e "[#@]" $dhdl | wc -l | awk '{print dl=1/($1-1)}'`
		grep -v -e "[#@]" $dhdl | awk -v dl=$dl -v s=$s '{a+=$2*dl; print $1,s*a}' > file.wrk
		tail -1 file.wrk | awk '{print $2}'>> ../../$dirdata/${B}-${A}_b_$tb.wrk
	    else
		echo "no dhdl file in b-${B}-${A}/$i directory"
	    fi
	    cd ../
	done
	cd ../
    fi
fi

rm $dirdata/${A}-${B}_u_$tu.wrk >& /dev/null
rm $dirdata/${B}-${A}_u_$tu.wrk >& /dev/null

if [ $uw == 1 ] ; then 
    echo "Doing unbound state... " $A "->" $B
    if  [ -d u-${A}-${B} ] ; then
	cd u-${A}-${B}
	for i in u[0-9]*; do
	    cd $i 
	    if [ -f $dhdl ] ; then
		dl=`grep -v -e "[#@]" $dhdl | wc -l | awk '{print dl=1/($1-1)}'`
		grep -v -e "[#@]" $dhdl | awk -v dl=$dl -v s=$s '{a+=$2*dl; print $1,s*a}' > file.wrk
		tail -1 file.wrk | awk '{print $2}' >> ../../$dirdata/${A}-${B}_u_$tu.wrk
	    else
		echo "no dhdl file in u-${A}-${B}/$i directory"
	    fi
	    cd ../
	done
	cd ../
    fi
    echo "Doing unbound state... " $B "->" $A
    if  [ -d u-${B}-${A} ] ; then
	cd u-${B}-${A}
	for i in u[0-9]*; do
	    cd $i 
	    if [ -f $dhdl ] ; then
		dl=`grep -v -e "[#@]" $dhdl | wc -l | awk '{print dl=1/($1-1)}'`
		grep -v -e "[#@]" $dhdl | awk -v dl=$dl -v s=$s '{a+=$2*dl; print $1,s*a}' > file.wrk
		tail -1 file.wrk | awk '{print $2}' >> ../../$dirdata/${B}-${A}_u_$tu.wrk
	    else
		echo "no dhdl file in u-${B}-${A}/$i directory"
	    fi
	    cd ../
	done
	cd ../
    fi
fi

exit 
