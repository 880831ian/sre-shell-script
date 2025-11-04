#!/bin/bash

# 設定區
domain="<domain>"  # 要檢查的網址
http_code="200"                      # 要檢查的 HTTP 狀態碼
time_out_sec=1                       # 設定超時秒數
log_file="$(basename "$0" .sh)_$(date +"%Y%m%d_%H%M%S").log"  # 加入時間戳的檔案名稱

# 初始化計數器
success_count=0
failure_count=0

# 顏色設定
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[0m"

# 無窮循環
echo -e "\n開始檢查連線 ..." | tee -a $log_file
echo -e "檢查網址: ${BLUE}${domain}${WHITE}" | tee -a $log_file
echo -e "檢查 HTTP 狀態碼: ${BLUE}${http_code}${WHITE}\n" | tee -a $log_file

while true; do
    # 執行 curl 並記錄 response code 和總花費時間
    result=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" -I -m ${time_out_sec} "${domain}")
    response=$(echo "$result" | awk '{print $1}')
    time_taken=$(echo "$result" | awk '{print $2}')

    if [ "$response" == "$http_code" ]; then
        ((success_count++))
        echo -e "$(date +"%T") - ${GREEN}連線成功${WHITE} (HTTP ${BLUE}${http_code}${WHITE}) - 花費時間: ${YELLOW}${time_taken}s${WHITE}" | tee -a $log_file
    else
        ((failure_count++))
        echo -e "$(date +"%T") - ${RED}連線失敗${WHITE} - HTTP 狀態碼: ${BLUE}${response}${WHITE} - 花費時間: ${YELLOW}${time_taken}s${WHITE}" | tee -a $log_file
    fi

    if [ $(((failure_count + success_count) % 10)) -eq 0 ]; then
        echo -e "\n成功次數: ${GREEN}${success_count}${WHITE} - 失敗次數: ${RED}${failure_count}${WHITE} - 總共次數: ${BLUE}$((failure_count + success_count))${WHITE}\n" | tee -a $log_file
    fi
done