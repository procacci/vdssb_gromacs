#!/bin/bash
#
# Generate pdb of best docked pose ligand-receptor
# must use autodock4.6.2
# downloaded from http://autodock.scripps.edu/ as autodocksuite-4.2.6-x86_64Linux2.tar
#
# mgltools must also be installed in your homedir
# (written by P.Procacci, UNIFI 2020)
#

# setup python instruments

if [ ! -d ~/mgltools ] ; then
    echo " no mgltools dir found in your home "
    echo "download and install mgltools_x86_64Linux2_1.5.6.tar.gz in your homedir"
    exit
fi

pysh=~/mgltools/bin/pythonsh
plig=~/mgltools/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py
prec=~/mgltools/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py
pfle=~/mgltools/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_flexreceptor4.py
pgrid=~/mgltools/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_gpf4.py
ppar=~/mgltools/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_dpf4.py

n=50
g=0.375
p=40
while getopts ":l:r:x:y:z:n:g:p:f:d:" opt; do 
    case $opt in 
	l)
	    ligand=$OPTARG;
	    ;;
	r) 
	    receptor=$OPTARG; 
	    ;;
	x) 
	    x=$OPTARG; 
	    ;;
	y) 
	    y=$OPTARG; 
	    ;;
	z) 
	    z=$OPTARG; 
	    ;;
	n) 
	    n=$OPTARG; 
	    ;;
	g) 
	    g=$OPTARG; 
	    ;;
	p) 
	    p=$OPTARG;
	    ;;
	f) 
	    f=$OPTARG;
	    ;;
	d) 
	    d=$OPTARG;
	    ;;
    esac
done

   
###### function dodockfiles BEGINS ####################################
function dodockfiles {
    best=`grep "^   1 |" $1 | awk '{print $5}'`
    free=`grep "^   1 |" $1  | awk '{print $3}'`

    echo " Generating  the best docked" $best " complex with DG = "$free 
    
    grep '^DOCKED' $1  | cut -c9- | awk -v run=$best '{if($1=="MODEL" && $2 == run) {ok=1}; if(ok==1 && $1 == "ATOM") {print}; if($1=="ENDMDL") {ok=0}}' | sed "s/  1   /-10   /g" > bestdocked.pdb
    
    cat bestdocked.pdb $receptor.pdbqt  > complex_${ligand}.pdbqt
    obabel -i pdbqt complex_${ligand}.pdbqt -opdb -O complex_${ligand}.pdb
    sed -i "s/  -10 /A   0 /g" complex_${ligand}.pdb
    awk '{if($6==0) {i++;printf "%14s%.2X %-70s\n",  substr($0,1,14),i,substr($0,18,70)} else {print}}' complex_$ligand.pdb  > x.pdb ; mv x.pdb complex_$ligand.pdb
    # generate 9 (or less) best docked states trajectory
    rm traj_$ligand.pdb >& /dev/null
    for i  in {1..9}; do
	best=`grep "^   $i |" $1 | awk '{print $5}'`
	free=`grep "^   $i |" $1  | awk '{print $3}'`
	if [[ ! -z $best ]] ; then
	    grep '^DOCKED' $1  | cut -c9- | awk -v run=$best '{if($1=="MODEL" && $2 == run) {ok=1}; if(ok==1 && $1 == "ATOM") {print}; if($1=="ENDMDL") {ok=0}}' | sed "s/  1   /-10   /g" > tmp.pdb
	    echo "REMARK "$best $free >> traj_$ligand.pdb
 	    cat tmp.pdb >> traj_$ligand.pdb
	    cat $receptor.pdbqt >> traj_$ligand.pdb
	    echo "END" >> traj_$ligand.pdb
	fi
    done
    rm tmp* >& /dev/null 
}
####### function dodockfiles ENDS ##########################################


echo "options:"
echo " CENTER -->      x =" $x " y =" $y " z =" $z
echo " grid = " $g "   npts =" $p  "   rounds =" $n
echo " Flexible residues -->  " $f

if [ $# == "0" ] ; then 
    echo ""
    echo "This script find best docking pose of a ligand to a receptor using Autodock4 "
    echo ""
    echo " Syntax: docking.bash  -l ligand -r receptor  [ opt ]"
    echo "          where  'ligand' assumes that file ligand.pdb exist"
    echo "                 'receptor' assumes that file receptor.pdb exist"
    echo "          "
    echo "          Options:"
    echo "          -x xcord -y ycord -z zcord "
    echo "          Specifies the ocking center on the receptor"
    echo "          "
    echo "          -n nrounds"
    echo "          Specifies the number of Docking rounds (default 50)"
    echo "          "
    echo "          -g gridspace"
    echo "          Specifies 40x40x40 grid spacing (default 0.375) "
    echo "          -p NP "
    echo "          Specifies  NP x NP x NP point with def grid spacing (default 0.375) "
    echo "          -f list "
    echo "          Specifies flexible residues in the protein (list must be enclosed in ellypsis) "
    echo "          Example:  docking.bash -l lig -r rec [..] -f \"ARG4_GLU290\"  "
    echo "          -d dlg-file "
    echo "           read the dlg file and produce best docked complex and best 10 dockes states "
    exit
fi

# if $d is set the read the dlg file and exit
if [[ ! -z $d ]]; then
    if [ -f $d ] ; then
	echo "Process dlg file and the exit "
	dodockfiles $d
	exit
    else
	echo "cannot fine file $d"
	exit
    fi
fi


if [[ ! -v ligand  ]] ; then
    echo " Syntax: docking.bash  -l ligand -r receptor"
    echo " ligand not provided; provide filename of the ligand " 
    exit
fi
if [[ ! -v receptor ]] ; then
    echo " Syntax: docking.bash  -l ligand -r receptor"
    echo " receptor not provided; provide filename of the receptor " 
    exit
fi
if [ ! -f $ligand.pdb  ]; then
    echo "file" $ligand.pdb " not found"
    exit
fi
if [ ! -f $receptor.pdb  ]; then
    echo "file" $receptor.pdb " not found"
    exit
fi

echo " Generating ligand and receptor pdbqt file "

$pysh  $plig -l $ligand.pdb    >& /dev/null
$pysh  $prec -r $receptor.pdb >& /dev/null

echo " Preparing the receptor gpf file"

if [[ ! -z $f ]] ; then
    # flexible residues are present
    $pysh $pfle -r $receptor.pdbqt -s $f >& /dev/null
    flex=${receptor}_flex.pdbqt 
    receptor=${receptor}_rigid
    $pysh $pgrid  -l $ligand.pdbqt -x $flex -r $receptor.pdbqt >& /dev/null
else
    # fully rigid receptor
    $pysh $pgrid  -l $ligand.pdbqt  -r $receptor.pdbqt >& /dev/null
fi


# put the box center in the dpf file if this is given
if [ -v x -a -v y -a -v z ] ; then
    sed -i "s/gridcenter auto/gridcenter $x $y $z/g" $receptor.gpf  
fi

# set grid spacing 
sed -i "s/spacing 0.375/spacing $g/g" $receptor.gpf  
sed -i "s/npts 40 40 40/npts $p $p $p/g" $receptor.gpf  

echo " Generating maps "
autogrid4 -p $receptor.gpf -l $receptor.glg 

#Preparing the Docking parameter file 

$pysh  $ppar -l $ligand.pdbqt -r $receptor.pdbqt >& /dev/null
sed -i "s/ga_run 10/ga_run $n/" ${ligand}_${receptor}.dpf

# fix extedended issue
sed -i "s/model extended/model bound/" ${ligand}_${receptor}.dpf

# if $f is non-void, add flexres and flx_res atom_types to the dpf file
if [[ ! -z $f ]] ; then
    awk -v ffile=$flex '{print}END{print "flexres " ffile}' ${ligand}_${receptor}.dpf > tmp;
    str=`grep -e "^map" $receptor.gpf | awk -F "." '{ printf "%3s",$2}'`
    grep -e "^map" $receptor.gpf > tmp.maps
    nmaps=`wc -l tmp.maps | awk '{print $1}'`
#   update the maps lines in dpf 
    awk -v str="$str" -v nm=$nmaps\
     '{\
         if($1=="ligand_types") {\
     	print $1,str\
         }\
         else\
         {\
     	if(NR>nm) {\
     	    if($1=="fld") {\
     		print $0;\
     		for (i=1; i<=nm; i++) {\
     		    print "map " mapn[i]\
     		}\
     	    }\
     	    else {\
     		if($1 !="map") {print};\
     	    }\
     	}\
     	else{\
     	    mapn[NR]=$2;\
     	}\
         }\
     }'\
     tmp.maps tmp > ${ligand}_${receptor}.dpf 
fi

# All is done. We can run autodock 
echo " Docking... (may take some time) "
autodock4 -p ${ligand}_${receptor}.dpf -l ${ligand}_${receptor}.dlg

d=${ligand}_${receptor}.dlg

dodockfiles $d  #call the function that printout dock files  

exit

