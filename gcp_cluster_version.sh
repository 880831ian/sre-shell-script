#!/bin/bash

# 設定搜尋的 GKE 版本
VERSION_1_25="1.25"
VERSION_1_26="1.26"
VERSION_1_27="1.27"
VERSION_1_28="1.28"

# 清空舊的記錄
echo -n "" >1.26.txt
echo -n "" >1.27.txt
echo -n "" >1.28.txt

echo "Scanning all GCP projects for GKE Node Pool versions..."

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

        echo "  Checking cluster: $CLUSTER (Location: $LOCATION)"

        # 取得該叢集內的所有 Node Pool 版本，隱藏錯誤輸出
        NODE_POOLS=$(gcloud container node-pools list --project "$PROJECT" --cluster "$CLUSTER" --location "$LOCATION" --format="value(name,version)" 2>/dev/null)

        # 檢查是否有權限
        if [[ $? -ne 0 ]]; then
            echo "    ❌ 無權限存取此叢集: $CLUSTER"
            continue
        fi

        while read -r NODE_POOL VERSION; do
            if [[ -z "$NODE_POOL" || -z "$VERSION" ]]; then
                continue
            fi

            # 解析版本並區分輸出
            if [[ "$VERSION" == "$VERSION_1_25"* ]]; then
                echo "    🔴  Node Pool: $NODE_POOL (Version: $VERSION) matches target version ($VERSION_1_25)"
                echo "$PROJECT,$CLUSTER,$NODE_POOL,$VERSION" >>1.25.txt
            elif [[ "$VERSION" == "$VERSION_1_26"* ]]; then
                echo "    🔴  Node Pool: $NODE_POOL (Version: $VERSION) matches target version ($VERSION_1_26)"
                echo "$PROJECT,$CLUSTER,$NODE_POOL,$VERSION" >>1.26.txt
            elif [[ "$VERSION" == "$VERSION_1_27"* ]]; then
                echo "    🟠 Node Pool: $NODE_POOL (Version: $VERSION) matches target version ($VERSION_1_27)"
                echo "$PROJECT,$CLUSTER,$NODE_POOL,$VERSION" >>1.27.txt
            elif [[ "$VERSION" == "$VERSION_1_28"* ]]; then
                echo "    🟡  Node Pool: $NODE_POOL (Version: $VERSION) matches target version ($VERSION_1_28)"
                echo "$PROJECT,$CLUSTER,$NODE_POOL,$VERSION" >>1.28.txt
            fi
        done <<<"$NODE_POOLS"

    done <<<"$CLUSTERS"
done

echo "Scan completed. Results saved to 1.26.txt and 1.27.txt and 1.28.txt"
