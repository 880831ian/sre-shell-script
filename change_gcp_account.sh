#!/bin/bash
set -e

#=========================================
# 配置多帳號對應專案 / 區域 / GKE Cluster
emails=("<email>")
projects=("<project id>")

#=========================================
# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # reset

#=========================================
# 選擇帳號
PS3='請選擇要使用的 Google 帳號(輸入開頭數字): '
select reply_email in "${emails[@]}"; do
    if [[ -n "$reply_email" ]]; then
        for i in "${!emails[@]}"; do
            if [[ "${emails[$i]}" == "$reply_email" ]]; then
                index=$i
                break
            fi
        done
        email=${emails[$index]}
        project_id=${projects[$index]}
        echo -e "\n選擇 ${YELLOW}$email${NC} 對應專案 ${YELLOW}$project_id${NC}${NC}"
        break
    else
        echo -e "${RED}無效選項 ($REPLY)，請重新輸入${NC}"
    fi
done

#=========================================
# 檢查帳號是否已登入
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "^$email$"; then
    echo -e "${BLUE}🔐 尚未登入帳號 $email，開始登入...${NC}"
    gcloud auth login "$email"
else
    echo -e "${GREEN}✅ 帳號 $email 已登入${NC}"
fi

#=========================================
# 建立 / 啟用 gcloud config profile
config_name="cfg-${email%%@*}"
config_name=$(echo "$config_name" | tr '_' '-')
if ! gcloud config configurations list --format="value(name)" | grep -q "^$config_name$"; then
    echo -e "${BLUE}📂 建立 gcloud configuration: $config_name${NC}"
    gcloud config configurations create "$config_name"
fi
gcloud config configurations activate "$config_name"

#=========================================
# 設定 project / account
gcloud config set account "$email"
gcloud config set project "$project_id"

#=========================================
# 設定 ADC quota project
echo -e "${BLUE}⚡ 設定 Application Default Credentials (ADC) quota project${NC}"
gcloud auth application-default login --quiet
gcloud auth application-default set-quota-project "$project_id"

#=========================================
# 清除 kube cache 避免 gke_gcloud_auth_plugin 錯誤
rm -rf ~/.kube/gke_gcloud_auth_plugin_cache
rm -rf ~/.kube/cache/ ~/.kube/http-cache/

#=========================================
# 顯示設定 summary
echo -e "\n${GREEN}🎉 設定完成！${NC}"
echo -e "帳號: ${YELLOW}$email${NC}"
echo -e "專案: ${YELLOW}$project_id${NC}"
echo -e "gcloud configuration: ${YELLOW}$config_name${NC}"
echo ""