#!/bin/bash

args=$#
if (( args != 1 ))
then
	echo "Параметры запуска системы заданы неверно(1)!"
	exit 1
fi
currentVKOType=$1
if (( currentVKOType > 2 )) || (( currentVKOType < 0 ))
then
	echo "Параметры запуска системы заданы неверно(2)!"
	exit 2
fi

# ------------------------------------------
#	Vars and consts
# ------------------------------------------


declare -a TargetsId # ID Xcurr Ycurr SpeedX SpeedY SpottedFlag IdentifiedFlag

NoTarget=0

# ------------------------------------------
#	Common includes
# ------------------------------------------

source "params.sh"
source "CommonFuncs.sh"


# ------------------------------------------
#	Specific
# ------------------------------------------


TYPE="unk"
TYPELOG="unk"
MAXOFTYPE=0
CANDESTROY=(0 0 0) #0-br 1-plan 2-cmiss
SetParamsBySystemID $currentVKOType # Setting all specific params

# ------------------------------------------
#	Program
# ------------------------------------------

CheckConditions
trap sigint_handler 2 


commfile="$DirectoryCommLog/$TYPELOG.log"
mkdir $DirectoryComm >/dev/null 2>/dev/null
mkdir $DirectoryCommLog >/dev/null 2>/dev/null
rm -rf $DirectoryComm/$TYPELOG* 2>/dev/null
rm -rf $DirectoryCommLog/$TYPELOG* 2>/dev/null

echo "Система $TYPE успешно инициализирована!" | base64 >>$commfile

HeartBeatInit $TYPELOG

while :
do
	GetTargetsList # Result in $Targets

	for target in $Targets
	do
	 if [ "$target" ]
	 then 
	  IDTarget=`expr substr $target 11 6`;
	  readedfile=`tail $DirectoryTargets/$target 2>/dev/null`;result=$?;
	  if (( $result == 0 ))
	  then
	   XYTarget=($readedfile);
       isNewIDinList "7" "$IDTarget"; idx=$returnIdx;
	   if (( $idx == -1 ))
	   then
	    # New element	
	    TargetsId[0+7*$NoTarget]=$IDTarget
	    TargetsId[1+7*$NoTarget]=${XYTarget[0]}
	    TargetsId[2+7*$NoTarget]=${XYTarget[1]}
	    TargetsId[3+7*$NoTarget]=0
	    TargetsId[4+7*$NoTarget]=0
	    TargetsId[5+7*$NoTarget]=0	
	    TargetsId[6+7*$NoTarget]=-1
		cIdx=$NoTarget
	    let NoTarget+=1
	   else
	    # Old element
		if (( ${TargetsId[3+7*$idx]} == 0 )) && (( ${TargetsId[1+7*$idx]} != ${XYTarget[0]} ))
		  # if speed was not calculated and  coord are differs
		  then
			checkDetection $TYPE $MAXOFTYPE ${TargetsId[1+7*$idx]} ${TargetsId[2+7*$idx]}; det1=$?
			checkDetection $TYPE $MAXOFTYPE ${XYTarget[0]} ${XYTarget[1]}; det2=$?
			if (($det1 == 1)) && (( $det2 == 1 ))
 			then
	  	      let TargetsId[3+7*$idx]=(${XYTarget[0]}-${TargetsId[1+7*$idx]})
			  let TargetsId[4+7*$idx]=(${XYTarget[1]}-${TargetsId[2+7*$idx]})
			fi
	 	 fi	
	  	 TargetsId[1+7*$idx]=${XYTarget[0]}
		 TargetsId[2+7*$idx]=${XYTarget[1]}
		 cIdx=$idx
	   fi
 		
		# Detection
		if (( ${TargetsId[5+7*$cIdx]} == 0 ))
		then
		  i=0
	      while [[ "$i" < "$MAXOFTYPE" ]]
  	      do
	        checkinAreaByType $TYPE $i ${TargetsId[1+7*$cIdx]} ${TargetsId[2+7*$cIdx]};  spotted=$?
	        let i+=1
	        if [[ "$spotted" == "1" ]]
	        then
  		  	  TargetsId[5+7*$cIdx]=1
	          echo $TYPE" $i: Цель ID:${TargetsId[0+7*$cIdx]} обнаружена" \
					"${TargetsId[1+7*$cIdx]}  ${TargetsId[2+7*$cIdx]}" | base64  >>$commfile

	        fi
	      done
	    fi
 		# Identification
		if (( ${TargetsId[6+7*$cIdx]} == -1 )) && (( ${TargetsId[3+7*$cIdx]} != 0 ))
	  	  then
	    	TargetTypeBySpeed ${TargetsId[3+7*$cIdx]}
		    TargetsId[6+7*$cIdx]=$?
	  	    i=0
	        while [[ "$i" < "$MAXOFTYPE" ]]
  	          do
		        checkinAreaByType $TYPE $i ${TargetsId[1+7*$cIdx]} ${TargetsId[2+7*$cIdx]};  spotted=$?
		        let i+=1
				if (( $spotted == 1 ))
				then
		         case ${TargetsId[6+7*$cIdx]} in
		          0 )
		            echo "$TYPE $i: Цель ID:${TargetsId[0+7*$cIdx]} идентифицирована как Бал.блок" \
				 		" (${TargetsId[3+7*$idx]}  ${TargetsId[4+7*$idx]})" | base64  >>$commfile
		            ;;
 		          1 )
		            echo "$TYPE $i: Цель ID:${TargetsId[0+7*$cIdx]} идентифицирована как Самолет" \
				 		" (${TargetsId[3+7*$idx]}  ${TargetsId[4+7*$idx]})" | base64  >>$commfile
		            ;;
		          2 )
		            echo "$TYPE $i: Цель ID:${TargetsId[0+7*$cIdx]} идентифицирована как К.ракета" \
				 		" (${TargetsId[3+7*$idx]}  ${TargetsId[4+7*$idx]})" | base64  >>$commfile
		         esac
				 
				 if [[ $TYPE == "РЛС" ]]
				 then
					 checkSPRODir ${TargetsId[1+7*$cIdx]}  ${TargetsId[2+7*$cIdx]} \
							${TargetsId[3+7*$cIdx]}  ${TargetsId[4+7*$cIdx]}
					 direction=$?
					 if (( $direction == 1 ))
					 then
				       echo $TYPE" $i: Цель ID:${TargetsId[0+7*$cIdx]} движется в направлении СПРО" | base64  >>$commfile
					 fi
				 fi
  				fi
			done
 		fi

		# Destroy
		if (( ${TargetsId[6+7*$cIdx]} != -1 ))
	  	then		
		  if (( "${CANDESTROY[${TargetsId[6+7*$cIdx]}]}" == "1" ))
			then
			  touch "$DestroyDirectory/${TargetsId[0+7*$cIdx]}"
			fi
		fi

	  fi
	 fi
	done
	
	#echo "END OF CYCLE"
	#stime=`date +%s`
	#etime=`date +%s`;((time=$etime-$stime));if (($time > 0));then echo "Cycle time = $time s."; fi

	HeartBeat $TYPELOG
	RandomSleep
done
