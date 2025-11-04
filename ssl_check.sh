#!/bin/sh

# 定義要連接的主機和端口
HOST="$1"
PORT=443

# 顏色設定
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[0m"

# 檢查區塊
[ -z "$HOST" ] && printf "${RED}請於腳本後輸入要檢查的網址 例如：ssl_check.sh google.com${WHITE}\n" && exit 1
url_regex='^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}(\S*)$'
[[ ! $1 =~ $url_regex ]] && printf "${RED}請輸入符合 URL 格式的網址 (不需要 https://)\n" && exit 1
response=$(curl -m 1 -Is "$HOST" | head -n 1)
[[ -z "$response" || "$response" =~ "404" ]] && printf "${RED}網站無法正常連線，請檢查網址是否正確${WHITE}\n" && exit 1

# openssl 指令檢查
printf "${BLUE}HOST:${WHITE} ${YELLOW}$HOST${WHITE}\n"
start_datetime=$(echo | openssl s_client -servername "$HOST" -connect "$HOST":$PORT 2>/dev/null | openssl x509 -noout -startdate | cut -d "=" -f 2)
end_datetime=$(echo | openssl s_client -servername "$HOST" -connect "$HOST":$PORT 2>/dev/null | openssl x509 -noout -enddate | cut -d "=" -f 2)

# 將日期轉換的AWK指令放入函數中
convert_date() {
    echo "$1" | awk '{printf "%s-%02d-%02d %s\n", $4, (index("JanFebMarAprMayJunJulAugSepOctNovDec",$1)+2)/3, $2, $3}'
}

custom_start_datetime=$(convert_date "$start_datetime")
custom_end_datetime=$(convert_date "$end_datetime")
printf "發行日期：${GREEN}$custom_start_datetime${WHITE}\n到期日期：${RED}$custom_end_datetime${WHITE}\n"
