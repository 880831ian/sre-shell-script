#!/bin/bash

ORG_ID="<org id>"
TARGET_ZONE="asia-east1-b"
FILTER_RAW="n2,n2d"

REGION="${TARGET_ZONE%-*}"  # 取得區域名稱
IFS=',' read -r -a FILTERS <<< "$FILTER_RAW"
# 建立對應 CSV 檔案，含標題列
for FILTER in "${FILTERS[@]}"; do
  FILE_NAME="gke_${FILTER}_node_report.csv"
  echo "Project ID,Cluster Name,Location,Node Pool Name,Machine Type,Node Count" > "$FILE_NAME"
done

# 列出所有 Org 內的專案（含 folders 中）
gcloud asset search-all-resources \
  --scope="organizations/${ORG_ID}" \
  --asset-types="cloudresourcemanager.googleapis.com/Project" \
  --format="value(name)" | sed 's|.*/||' | sort -r | while read -r PROJECT_ID; do

  echo "[INFO] Scanning project: $PROJECT_ID"

  CLUSTERS=$(gcloud container clusters list \
    --project="$PROJECT_ID" \
    --format=json 2>/dev/null || true)

  # 檢查是否有 GKE 叢集
  if [[ -z "$CLUSTERS" || $(echo "$CLUSTERS" | jq 'length') -eq 0 ]]; then
    continue
  fi

  echo "$CLUSTERS" | jq -c '.[]' | while read -r CLUSTER; do
    CLUSTER_NAME=$(echo "$CLUSTER" | jq -r '.name')
    LOCATION=$(echo "$CLUSTER" | jq -r '.location')

    # 判斷是 region 還是 zone（區分方式：region 無 '-' 第三段）
    if [[ "$LOCATION" =~ ^[a-z]+-[a-z]+[0-9]$ ]]; then
    # 是 regional
    NODEPOOLS=$(gcloud container node-pools list \
        --project="$PROJECT_ID" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --format=json 2>/dev/null || true)
    else
    # 是 zonal
    NODEPOOLS=$(gcloud container node-pools list \
        --project="$PROJECT_ID" \
        --cluster="$CLUSTER_NAME" \
        --zone="$TARGET_ZONE" \
        --format=json 2>/dev/null || true)
    fi

    # 檢查是否有 Node Pool
    if [[ -z "$NODEPOOLS" || $(echo "$NODEPOOLS" | jq 'length') -eq 0 ]]; then
      continue
    fi

    echo "$NODEPOOLS" | jq -c '.[]' | while read -r POOL; do
      NODE_POOL_NAME=$(echo "$POOL" | jq -r '.name')
      MACHINE_TYPE=$(echo "$POOL" | jq -r '.config.machineType')

      # 查 instance group URL 的實際節點數
      INSTANCE_GROUP_URL=$(echo "$POOL" | jq -r --arg ZONE "$TARGET_ZONE" '.instanceGroupUrls[] | select(test($ZONE))' | head -n 1)

      if [[ -n "$INSTANCE_GROUP_URL" && "$INSTANCE_GROUP_URL" != "null" ]]; then
        INSTANCE_GROUP_NAME=$(basename "$INSTANCE_GROUP_URL")

        NODE_RAW=$(gcloud compute instance-groups list-instances "$INSTANCE_GROUP_NAME" \
          --zone="$TARGET_ZONE" \
          --project="$PROJECT_ID" \
          --format="value(NAME)")

        if [[ -n "$NODE_RAW" && "$NODE_RAW" != "null"  ]]; then
            NODE_COUNT=$(echo "$NODE_RAW" | wc -l | xargs)
            else
            NODE_COUNT=0
        fi
      else
        continue
      fi

      for FILTER in "${FILTERS[@]}"; do
        if [[ "$MACHINE_TYPE" =~ ^${FILTER}(-|$) ]]; then
          ROW="${PROJECT_ID},${CLUSTER_NAME},${TARGET_ZONE},${NODE_POOL_NAME},${MACHINE_TYPE},${NODE_COUNT}"
          echo "$ROW" | tee -a "gke_${FILTER}_node_report.csv"
        fi
      done

    done
  done
done