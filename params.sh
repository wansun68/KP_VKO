# ------------------------------------------
#	System vars
# ------------------------------------------

TempDirectory=/tmp/GenTargets
DirectoryTargets="$TempDirectory/Targets"
DestroyDirectory="$TempDirectory/Destroy"
DirectoryComm="$TempDirectory/Comm"
DirectoryCommLog="$TempDirectory/CommLog"
LogFile=$TempDirectory/GenTargets.log

# ------------------------------------------
#	Location params
# ------------------------------------------

MaxRLS=3
MaxZRDN=3
MaxSPRO=1

declare -a RLS  # x y a r fov
#1
RLS[0+5*0]=6000
RLS[1+5*0]=6000
RLS[2+5*0]=270
RLS[3+5*0]=4500
RLS[4+5*0]=48
#2
RLS[0+5*1]=2500
RLS[1+5*1]=3600
RLS[2+5*1]=135
RLS[3+5*1]=3000
RLS[4+5*1]=120
#3
RLS[0+5*2]=5500
RLS[1+5*2]=3750
RLS[2+5*2]=225
RLS[3+5*2]=6000
RLS[4+5*2]=90

declare -a ZRDN  # x y r
#1
ZRDN[0+3*0]=6200
ZRDN[1+3*0]=3500
ZRDN[2+3*0]=600
#1
ZRDN[0+3*1]=5500
ZRDN[1+3*1]=3750
ZRDN[2+3*1]=400
#1
ZRDN[0+3*2]=4400
ZRDN[1+3*2]=3750
ZRDN[2+3*2]=650

declare -a SPRO  # x y r
#1
SPRO[0+3*0]=3250
SPRO[1+3*0]=3400
SPRO[2+3*0]=1000



function SetParamsBySystemID
{
	local cType=$1; 
	case $cType in
	 0 )	# RLS
		TYPE="РЛС"
		TYPELOG="rls"
		MAXOFTYPE=$MaxRLS
		CANDESTROY=(0 0 0) #0-br 1-plan 2-cmiss
		;;
	 1 )	# ZRDN
		TYPE="зрдн"
		TYPELOG="zrdn"
		MAXOFTYPE=$MaxZRDN
		CANDESTROY=(0 1 1) #0-br 1-plan 2-cmiss
		;;
	 2 )	# SPRO
		TYPE="СПРО"
		TYPELOG="spro"
		MAXOFTYPE=$MaxSPRO
		CANDESTROY=(1 0 0) #0-br 1-plan 2-cmiss
		;;
    esac
}


function checkinSector()
{
	local i=$1
	local X=$2
	local Y=$3

	((x1=-1*${RLS[0+5*$i]}+$X))
	((y1=-1*${RLS[1+5*$i]}+$Y))
	#echo "$x1 $y1"

	local r1_=$(echo "sqrt ( (($x1*$x1+$y1*$y1)) )" | bc -l)
	r1=${r1_/\.*}


	if (( $r1 <= ${RLS[3+5*$i]} ))
	then
	  #echo "R is OK!"

	  #cosfi=$(echo "-$x1/$r1_" | bc -l); #echo $cosfi
	  local fi=$(echo | awk " { x=atan2($y1,$x1)*180/3.14; print x}"); fi=(${fi/\.*});
	  if [ "$fi" -lt "0" ]
	  then
	   ((fi=360+$fi))	   
	  fi

 	  ((fimax=${RLS[2+5*$i]}+${RLS[4+5*$i]}/2)); #echo $fimax
	  ((fimin=${RLS[2+5*$i]}-${RLS[4+5*$i]}/2)); #echo $fimin
 	  if (( $fi <= $fimax )) && (( $fi >= $fimin ))
	  then
	   # echo "fi is OK!"
	   return 1
	  fi
	fi

	return 0
}

function checkinCircle()
{
	local i=$1
	local X=$2
	local Y=$3
	local typeofvko=$4

	if (( typeofvko == 1 )); then
		((x1=-1*${SPRO[0+3*$i]}+$X))
		((y1=-1*${SPRO[1+3*$i]}+$Y))
	else
		((x1=-1*${ZRDN[0+3*$i]}+$X))
		((y1=-1*${ZRDN[1+3*$i]}+$Y))
	fi
	#echo "$x1 $y1"
	
	local r1_=$(echo "sqrt ( (($x1*$x1+$y1*$y1)) )" | bc -l)
	r1=${r1_/\.*}

	if (( typeofvko == 1 )); then
		if [ "$r1" -le "${SPRO[2+3*$i]}" ]
		then
		  #echo "R is OK!"
		  return 1
		fi
	else
		if [ "$r1" -le "${ZRDN[2+3*$i]}" ]
		then
		  #echo "R is OK!"
		  return 1
		fi
	fi

	return 0
}

function checkinAreaByType
{
	local type="$1"
	local no=$2
	local Xm=$3
	local Ym=$4

   	((X=$Xm/1000));X=${X/\.*}
	((Y=$Ym/1000));Y=${Y/\.*}

	case $type in
     "РЛС" )
        checkinSector $no $X $Y
	    spotted=$?
	    return $spotted
        ;;
     "СПРО" )
        checkinCircle $no $X $Y 1
	    spotted=$?
	    return $spotted
        ;;
     "зрдн" )
        checkinCircle $no $X $Y 2
	    spotted=$?
	    return $spotted
    esac	
}

function checkSPRODir
{
	local X=$1
	local Y=$2
	local spX=$3
	local spY=$4

	fi=$(echo | awk " { x=atan2($spY,$spX)*180/3.14; print x}"); fi=(${fi/\.*}); 
	if [ "$fi" -lt "0" ]
	then
	  ((fi=360+$fi))	   
	fi	
	#secho "fi = $fi"

	let X3=${SPRO[0+3*0]}-$X; let Y3=${SPRO[1+3*0]}-$Y;
	betta=$(echo | awk " { x=atan2($Y3,$X3)*180/3.14; print x}"); betta=(${betta/\.*});
	if [ "$betta" -lt "0" ]
	then
	  ((betta=360+$betta))	   
	fi	
	#echo "betta = $betta"

	r1_=$(echo "sqrt ( (($X3*$X3+$Y3*$Y3)) )" | bc -l);
	gamma=$(echo | awk " { x=atan2(${SPRO[2+3*0]},$r1_)*180/3.14; print x}"); gamma=(${gamma/\.*});
	if [ "$gamma" -lt "0" ]
	then
	  ((gamma=360+$gamma))	   
	fi	
	#echo "gamma = $gamma"


    ((fimax=$betta+$gamma)); 
    ((fimin=$betta-$gamma));
	if (( $fi <=  $fimax )) && (( $fi >=  $fimin ))
	then	 
	  #echo " SPRO DIRECTION!!! "
	  return 1
	fi

	return 0;
}
