#!/bin/bash

# 清空舊的記錄
echo -n "" >clusters_count.txt

echo "Scanning all GCP projects for GKE Clusters..."

TOTAL_CLUSTERS=0

# 取得所有專案 ID
PROJECTS=$(gcloud projects list --format="value(projectId)")

for PROJECT in $PROJECTS; do
    echo "Checking project: $PROJECT"

    # 嘗試取得該專案內的所有 GKE 叢集，隱藏錯誤輸出
    CLUSTERS=$(gcloud container clusters list --project "$PROJECT" --format="value(name,location)" 2>/dev/null)

    # 檢查是否有權限
    if [[ $? -ne 0 ]]; then
        echo "  ❌ 無權限存取此專案: $PROJECT"
        echo "$PROJECT,無權限存取" >>clusters_count.txt
        continue
    fi

    CLUSTER_COUNT=0
    CLUSTER_LIST=()

    while read -r CLUSTER LOCATION; do
        if [[ -z "$CLUSTER" || -z "$LOCATION" ]]; then
            continue
        fi

        CLUSTER_COUNT=$((CLUSTER_COUNT + 1))
        CLUSTER_LIST+=("    - $CLUSTER (Location: $LOCATION)")

    done <<<"$CLUSTERS"

    # 更新總 Cluster 計數
    TOTAL_CLUSTERS=$((TOTAL_CLUSTERS + CLUSTER_COUNT))

    # 記錄到 clusters_count.txt
    if [[ $CLUSTER_COUNT -gt 0 ]]; then
        echo "$PROJECT 有 $CLUSTER_COUNT 個 Cluster" | tee -a clusters_count.txt
        for CLUSTER_NAME in "${CLUSTER_LIST[@]}"; do
            echo "$CLUSTER_NAME" | tee -a clusters_count.txt
        done
        echo "" | tee -a clusters_count.txt
    fi
done

# 顯示並記錄總共的 Cluster 數量
echo "=============================="
echo "總共 $TOTAL_CLUSTERS 個 Clusters"
echo "==============================" | tee -a clusters_count.txt
