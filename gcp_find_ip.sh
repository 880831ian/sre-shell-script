#!/bin/bash

# 顏色設定
BLUE="\033[1;34m"
RED='\033[0;31m'
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# 檢查必要命令是否安裝，如果沒有安裝則提示用戶安裝
if ! command -v parallel 1>/dev/null; then
    read -r -e -p "本腳本需要安裝 parallel，請確認是否安裝並繼續執行？(Y/N)：" continue
    case $continue in
    Y | y)
        brew install parallel
        ;;
    N | n)
        echo -e "${RED}未安裝 parallel，退出腳本。${NC}"
        exit 1
        ;;
    *)
        echo -e "${RED}\n無效參數 ($REPLY)，請重新輸入${NC}\n"
        exit 1
        ;;
    esac
fi

echo "輸入你要找的關鍵字:"
read FILTER

SELECT_ARR=("quick" "all")
select SELECT in "${SELECT_ARR[@]}"; do
    case ${SELECT} in
        "quick")
            PROJECTS_ID=("<project id>" "<project id>")
            break
            ;;
        "all")
            PROJECTS_ID=($(gcloud projects list --format="value(PROJECT_ID)"))
            break
            ;;
        *)
            echo "請選擇有效選項"
            ;;
    esac
done

echo -e "\n\n${YELLOW}===== 開始掃描 =====${RESET}"

# 暫存結果與 URL
TMP_DIR=$(mktemp -d)
RESULT_FILE="${TMP_DIR}/results.txt"
URL_FILE="${TMP_DIR}/urls.txt"
> "$RESULT_FILE"
> "$URL_FILE"

# 搜尋函式
search_in_project() {
    local PROJECT_ID=$1
    local FILTER=$2
    local RESULT=""
    local RESOURCES=("search-all-resources" "forwarding-rules" "addresses" "instances")

    for RES in "${RESOURCES[@]}"; do
        # 動態更新當前正在掃描的專案與資源
        echo -ne "${BLUE}[掃描中] ${PROJECT_ID} -> ${RES}${RESET}\r"

        case $RES in
            "search-all-resources")
                RESULT=$(gcloud asset search-all-resources --scope=projects/${PROJECT_ID} --query="${FILTER}" --quiet 2>/dev/null)
                ;;
            "forwarding-rules")
                RESULT=$(gcloud compute forwarding-rules list --filter="${FILTER}" --project "${PROJECT_ID}" --quiet 2>/dev/null)
                ;;
            "addresses")
                RESULT=$(gcloud compute addresses list --filter="${FILTER}" --project "${PROJECT_ID}" --quiet 2>/dev/null)
                ;;
            "instances")
                RESULT=$(gcloud compute instances list --filter="${FILTER}" --project "${PROJECT_ID}" --quiet 2>/dev/null)
                ;;
        esac

        if [ ! -z "$RESULT" ]; then
            # 保存結果到檔案
            echo -e "${GREEN}[找到] ${PROJECT_ID} -> ${RES}${RESET}" >> "$RESULT_FILE"
            echo -e "$RESULT\n" >> "$RESULT_FILE"
            # 保存 URL
            echo "https://console.cloud.google.com/networking/addresses/list?project=${PROJECT_ID}" >> "$URL_FILE"
            break  # 找到就不用掃其他資源
        fi
    done
}

export -f search_in_project
export FILTER
export TMP_DIR
export RESULT_FILE
export URL_FILE
export BLUE GREEN RESET

# ------------------------------
# 並行執行，每個專案一個子進程
# ------------------------------
# 禁用 citation 訊息
parallel --no-notice -j 10 search_in_project ::: "${PROJECTS_ID[@]}" ::: "${FILTER}"

# 換行顯示掃描結果
echo -e "\n\n${YELLOW}===== 掃描結果 =====${RESET}"
cat "$RESULT_FILE"

# 統一延遲後開啟瀏覽器
if [ -s "$URL_FILE" ]; then
    echo -e "\n等待 3 秒後開啟瀏覽器..."
    sleep 3
    while read -r url; do
        open "$url"
        echo "已開啟傳送門: $url"
    done < "$URL_FILE"
fi

# 清理暫存
rm -rf "$TMP_DIR"
echo -e "\n${GREEN}所有專案掃描完成 ✅${RESET}"