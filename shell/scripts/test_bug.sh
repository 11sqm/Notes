#!/bin/bash

i=0
LOG_FILE="bug_run.log"
> "$LOG_FILE"

./bug.sh >> "$LOG_FILE" 2>&1    # 2>&1将文件描述符2（标准错误输出）重定向到文件描述符1（标准输出）
while [ $? -ne 1 ]
do
    let i+=1
    ./bug.sh >> "$LOG_FILE" 2>&1
done

echo -e "\n===== 输出记录 ====="
cat "$LOG_FILE"
echo -e "\n===== 成功运行次数 ====="
echo "bug.sh 成功运行了 $i 次"