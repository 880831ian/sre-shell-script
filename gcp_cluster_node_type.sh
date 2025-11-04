#!/bin/bash

# 清空舊的記錄
echo -n "" > node_types_count.txt

echo "Scanning all GCP projects for GKE Node Specifications..."

NODE_TYPE_COUNT_FILE="/tmp/node_types_count_temp.txt"
echo -n "" > "$NODE_TYPE_COUNT_FILE"

# 取得所有專案 ID
PROJECTS=$(gcloud projects list --format="value(projectId)")

for PROJECT in $PROJECTS; do
    echo "Checking project: $PROJECT"

    # 嘗試取得該專案內的所有 GKE 叢集，隱藏錯誤輸出
    CLUSTERS=$(gcloud container clusters list --project "$PROJECT" --format="value(name,location)" 2>/dev/null)

    # 檢查是否有權限
    if [[ $? -ne 0 ]]; then
        echo "  ❌ 無權限存取此專案: $PROJECT"
        continue
    fi

    while read -r CLUSTER LOCATION; do
        if [[ -z "$CLUSTER" || -z "$LOCATION" ]]; then
            continue
        fi

        echo "  Analyzing cluster: $CLUSTER (Location: $LOCATION)"

        # 取得每個 Cluster 的 node pools
        NODE_POOLS=$(gcloud container node-pools list --cluster "$CLUSTER" --project "$PROJECT" --region "$LOCATION" --format="value(name)" 2>/dev/null)

        if [[ $? -ne 0 ]]; then
            echo "      ❌ 無法取得 $CLUSTER 的 Node Pools"
            continue
        fi

        while read -r NODE_POOL; do
            if [[ -z "$NODE_POOL" ]]; then
                continue
            fi

            # 取得 node pool 的機器類型及數量
            NODE_CONFIG=$(gcloud container node-pools describe "$NODE_POOL" --cluster "$CLUSTER" --project "$PROJECT" --region "$LOCATION" --format="value(config.machineType,initialNodeCount)" 2>/dev/null)

            if [[ $? -ne 0 ]]; then
                echo "      ❌ 無法取得 $NODE_POOL 的 Node 設定"
                continue
            fi

            MACHINE_TYPE=$(echo "$NODE_CONFIG" | awk '{print $1}')
            NODE_COUNT=$(echo "$NODE_CONFIG" | awk '{print $2}')

            if [[ -z "$MACHINE_TYPE" || -z "$NODE_COUNT" ]]; then
                continue
            fi

            # 將結果追加到暫存檔
            echo "$MACHINE_TYPE $NODE_COUNT" >> "$NODE_TYPE_COUNT_FILE"

            echo "      - Node Pool: $NODE_POOL (Machine Type: $MACHINE_TYPE, Nodes: $NODE_COUNT)"
        done <<<"$NODE_POOLS"
    done <<<"$CLUSTERS"
done

# 統計機器類型並記錄到 node_types_count.txt
echo "Node Type Statistics:" > node_types_count.txt
sort "$NODE_TYPE_COUNT_FILE" | awk '{count[$1]+=$2} END {for (type in count) print type, count[type]}' | tee -a node_types_count.txt

echo "Node type statistics saved to node_types_count.txt"