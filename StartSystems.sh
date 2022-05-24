#!/bin/bash

source "CommonFuncs.sh"  2>/dev/null
res=$?

if [ $res != 0 ]; then
  echo "Невозможен запуск в интерпретаторе, отличном от BASH"
  exit 1
fi
CheckConditions


bash ./VKO.sh 0 &
rls_pid=$!; echo "Started RLS with PID=$rls_pid"
sleep 0.1

bash ./VKO.sh 1 &
zrdn_pid=$!; echo "Started zrdn with PID=$zrdn_pid"
sleep 0.1

bash ./VKO.sh 2 &
spro_pid=$!; echo "Started spro with PID=$spro_pid"
sleep 0.1

bash ./KP.sh #$rls_pid $zrdn_pid $spro_pid


echo "Завершение работы подсистемы РЛС";  disown $rls_pid 2>/dev/null; kill -9 $rls_pid 2>/dev/null; 
echo "Завершение работы подсистемы зрдн"; disown $zrdn_pid 2>/dev/null;  kill -9 $zrdn_pid 2>/dev/null;
echo "Завершение работы подсистемы СПРО"; disown $spro_pid 2>/dev/null;  kill -9 $spro_pid 2>/dev/null;
