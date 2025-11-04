#!/bin/bash

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 無色

# 檢查必要命令是否安裝，如果沒有安裝則提示用戶安裝
check_command() {
    if ! command -v cwebp 1>/dev/null; then
        read -r -e -p "本腳本需要安裝 ${1}，請確認是否安裝並繼續執行？(Y/N)：" continue
        case $continue in
        Y | y)
            brew install ${1}
            ;;
        N | n)
            echo -e "${RED}未安裝 ${1}，退出腳本。${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}\n無效參數 ($REPLY)，請重新輸入${NC}\n"
            exit 1
            ;;
        esac
    fi
}

# 檢查列表中的命令
commands_to_check=("webp")
for cmd in "${commands_to_check[@]}"; do
    check_command "$cmd"
done

# 抓當前執行目錄
CURRENT_DIR=$(pwd)

echo -e "${YELLOW}當前目錄：${BLUE}$CURRENT_DIR${NC}"
echo -e "${YELLOW}開始轉換圖片...${NC}"
count=0

# 支援格式：png, jpg, jpeg, svg
for file in "$CURRENT_DIR"/*.{png,jpg,jpeg,svg}; do
  [ -e "$file" ] || continue

  # 檔名不含路徑
  filename=$(basename "$file")
  filename_noext="${filename%.*}"

  # 執行轉換並隱藏輸出
  cwebp "$file" -o "${CURRENT_DIR}/${filename_noext}.webp" > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}已轉換並刪除：${filename}${NC}"
    rm "$file"
    count=$((count + 1))
  else
    echo -e "${RED}轉換失敗：${filename}${NC}"
  fi
done

echo -e "${YELLOW}全部完成！總共轉換了 ${GREEN}${count}${YELLOW} 個檔案。${NC}"
