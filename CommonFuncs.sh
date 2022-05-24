function CheckConditions
{
	if [[ $EUID -eq 0 ]]; then
	   echo "Невозможен запуск с правами администратора"
	   exit 1
	fi

	OS=`uname -s`
	if [[ $OS != "Linux" ]]; then
	   echo "Невозможен запуск в ОС, отличной от Linux"
	   exit 1
	fi	
	

	t1="1";
	t2="1";
	[[ $t1 == $t2 ]] 
	res=$?
	if [ $res != 0 ]; then
	   echo "Невозможен запуск в интерпретаторе, отличном от BASH"
	   exit 1
	fi	
}

sigint_handler() { echo "";echo "Завершение работы системы $TYPE" ; exit 0;} 


function GetTargetsList
{
	Targets=`ls -tr $DirectoryTargets 2>/dev/null | grep id.`
	result=$?;
	if (( $result != 0 ))
	then
	  echo "Система не запущена!"
	  exit 0
	fi
}

returnIdx=0;
function isNewIDinList
{
  # if new returns -1
  # else returns index of element


  sizeofElem="$1"
  idcurr="$2";
  #shift
  #shift
  #declare -a list=("${@}")
  ((countofElem=${#TargetsId[@]}/sizeofElem)); #echo "ELEMENTS = $countofElem"

  returnIdx=-1
  i=0
  while (( "$i" < "$countofElem" ))
  do
    if [[ "${TargetsId[0+$sizeofElem*$i]}" == "$idcurr" ]]
    then
      returnIdx=$i
      break;#return "$i"
    fi
    let i+=1
  done
}

function checkDetection
{
	type="$1"
	maxoftype=$2
	X=$3
	Y=$4
    	i=0
	    while [[ "$i" < "$maxoftype" ]]
  	    do
	      checkinAreaByType $type $i $X $Y
	      spotted=$?
	      let i+=1
	      if [[ "$spotted" == "1" ]]
	        then
  		  	  return 1;
	      fi
	    done

}

function TargetTypeBySpeed
{
  #0-br 1-plan 2-cmiss
  speed=$1
  if (( $speed < 0 ))
  then
    let speed=-1*$speed;
  fi

  if (( $speed < 250 ))
  then
    return 1
  fi

  if (( $speed < 1000 ))
  then
    return 2
  fi

  if (( $speed < 10000 ))
  then
    return 0
  fi

  return 100
}


hbspro=0
hbzrdn=0
hbrls=0
function HeartBeatInit
{
	type="$1"
	filename=$DirectoryComm/$type
	echo "0" >$filename
	case $type in
     "rls" )
		hbrls=0
        ;;
     "spro" )
		hbspro=0
        ;;
     "zrdn" )
		hbzrdn=0
    esac
}
function HeartBeat
{
	type="$1"

	case $type in
     "rls" )
		let hbrls+=1
		echo "$hbrls" >$filename
        ;;
     "spro" )
 		let hbspro+=1
		echo "$hbspro" >$filename
        ;;
     "zrdn" )
		let hbzrdn+=1
		echo "$hbzrdn" >$filename
    esac

}

function RandomSleep
{
	rand=$((RANDOM%5+5))
	sltime=$(echo "$rand/10" | bc -l);
	sleep $sltime
}
