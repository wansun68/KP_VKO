
#!/bin/bash

# ------------------------------------------
#	Vars and consts
# ------------------------------------------

SYSPID=(0 0 0)
args=$#
if (( args == 3 )); then
	SYSPID[0]=$1
	SYSPID[1]=$2
	SYSPID[2]=$3
fi


SYSTEMS=("rls" "zrdn" "spro" "kp")
SYSTEMSDESCR=("РЛС" "зрдн" "СПРО")
HBVARS=("-1" "-1" "-1")
LOGLINES=("0" "0" "0")

STRTODEL=20
STRMAXCOUNT=100

# ------------------------------------------
#	Common includes
# ------------------------------------------

source "params.sh"
source "CommonFuncs.sh"


# ------------------------------------------
#	Specific
# ------------------------------------------

TYPE="КП"
TYPELOG="KP"
MAXOFTYPE=0
CANDESTROY=(0 0 0) #0-br 1-plan 2-cmiss

# ------------------------------------------
#	Program
# ------------------------------------------


commfile="$DirectoryCommLog/kp.log"

CheckConditions

trap sigint_handler 2 


echo "Система $TYPE успешно инициализирована!"
echo "Система $TYPE успешно инициализирована!" >>$commfile

sltime=0;

while :
do
	sleep 1
	let sltime+=1

	# display new log lines
    if (( sltime%2 == 0))
	then
		i=0
		while (( $i < 3 ))
		do
			lines=`wc -l "$DirectoryCommLog/${SYSTEMS[$i]}.log" 2>/dev/null`; res=$?
			if (( res == 0 )); then
				count=($lines); count=${count[0]}
				((LinesToDisplay=$count-${LOGLINES[$i]})); LOGLINES[$i]=$count; 
				if (( $LinesToDisplay > 0)); then
					readedfile=`tail -n $LinesToDisplay $DirectoryCommLog/${SYSTEMS[$i]}.log 2>/dev/null`;result=$?;
					if (( $result == 0 )); then
						echo "$readedfile" | base64 -d
					fi
				fi
			fi
			let i+=1
		done		
	fi

	# maintain all systems state
    if (( sltime%30 == 0))
	then
		echo "Запуск проверки всех систем"
		echo "Запуск проверки всех систем" >>$commfile
		i=0
		while (( $i < 3 ))
		do
			readedfile=`tail $DirectoryComm/${SYSTEMS[$i]} 2>/dev/null`;result=$?;
			if (( $result == 0 )); then
				if (( ${HBVARS[$i]} == $readedfile)); then
					echo "  Система ${SYSTEMSDESCR[$i]} зависла или остановлена."
					echo "  Система ${SYSTEMSDESCR[$i]} зависла или остановлена." >>$commfile
				else
					if (( ${HBVARS[$i]} == -1 )); then
						echo "  Получено начальное состояние системы ${SYSTEMSDESCR[$i]}."
						echo "  Получено начальное состояние системы ${SYSTEMSDESCR[$i]}." >>$commfile
					else
						echo "  Система ${SYSTEMSDESCR[$i]} работает в штатном режиме."
						echo "  Система ${SYSTEMSDESCR[$i]} работает в штатном режиме." >>$commfile
					fi
				fi
				HBVARS[$i]=$readedfile
			else
				echo "  Ошибка доступа к системе ${SYSTEMSDESCR[$i]}. Система неинициализирована или недоступна."
				echo "  Ошибка доступа к системе ${SYSTEMSDESCR[$i]}. Система неинициализирована или недоступна." >>$commfile
			fi
			let i+=1
		done
	fi

	# delete old log entries
    if (( sltime%10 == 0))
	then
		i=0
		while (( $i < 4 ))
		do
			lines=`wc -l "$DirectoryCommLog/${SYSTEMS[$i]}.log" 2>/dev/null`; res=$?
			if (( res == 0 )); then
				count=($lines); count=${count[0]}
				if (( $count >= $STRMAXCOUNT )); then
					echo "Файл ${SYSTEMS[$i]}.log. Строк $count. Допустимо $STRMAXCOUNT. Удаление первых $STRTODEL строк."
					echo "Файл ${SYSTEMS[$i]}.log. Строк $count. Допустимо $STRMAXCOUNT. Удаление первых $STRTODEL строк." >>$commfile

					deleted=`sed "1,$STRTODEL d" /tmp/GenTargets/CommLog/${SYSTEMS[$i]}.log`
					echo "$deleted" >/tmp/GenTargets/CommLog/${SYSTEMS[$i]}.log
					((LOGLINES[$i]=${LOGLINES[$i]}-$STRTODEL))
				fi				
			fi
			let i+=1
		done		
	fi
	
done
