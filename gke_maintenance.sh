#!/bin/bash

PROJECTS=$(gcloud projects list --format="value(projectId)")
for PROJECT_ID in $PROJECTS; do
  PROJECT_NAME=$(gcloud projects describe "$PROJECT_ID" --format="value(name)")
  STATUS=$?
  if [ $STATUS -ne 0 ] || [ -z "$PROJECT_NAME" ]; then
      echo "⚠️ 無法訪問 Project ${PROJECT_ID}，可能沒有權限或專案不存在"
      continue
  else
      echo "### Project ID: $PROJECT_ID | Project Name: $PROJECT_NAME"
  fi

  # 2. 取得該 project 所有 clusters
  if [[ -z "$REGION" ]]; then
    # 不指定 region，列出所有 cluster
    CLUSTERS=$(gcloud container clusters list --project="$PROJECT_ID" --format="value(name,location)")
  else
    # 指定 region，列出該 region cluster
    CLUSTERS=$(gcloud container clusters list --project="$PROJECT_ID" --region="$REGION" --format="value(name,location)")
  fi

  while IFS= read -r line; do
    CLUSTER_NAME=$(echo "$line" | awk '{print $1}')
    LOCATION=$(echo "$line" | awk '{print $2}')
    # 如果指定了 ZONE，且和 cluster location 不同，跳過
    if [[ -n "$ZONE" && "$LOCATION" != "$ZONE" ]]; then
      continue
    fi

    if [[ -z "$CLUSTER_NAME" || -z "$LOCATION" ]]; then
      continue
    fi

    echo "Cluster: $CLUSTER_NAME, Location: $LOCATION"

    CLUSTER_JSON=$(gcloud container clusters describe "$CLUSTER_NAME" \
    --project="$PROJECT_ID" \
    --zone="$LOCATION" \
    --format=json)

    gcloud container clusters describe "$CLUSTER_NAME" --project="$PROJECT_ID" --zone="$LOCATION" \
    --format=json | jq -r --arg project "$PROJECT_ID" --arg cluster "$CLUSTER_NAME" '
        .nodePools[]
        | select(.config.effectiveCgroupMode == "EFFECTIVE_CGROUP_MODE_V1")
        | "\($project),\($cluster),\(.name),\(.config.effectiveCgroupMode)"' >> gke_cgroup.log

    RAW_JSON=$(echo "$CLUSTER_JSON" | jq '.maintenancePolicy.window.recurringWindow')
    DEPT_LABEL=$(echo "$CLUSTER_JSON" | jq -r '.resourceLabels.dept // ""')
    ENV_LABEL=$(echo "$CLUSTER_JSON" | jq -r '.resourceLabels.env // ""')

    echo "== recurringWindow JSON =="
    echo "$RAW_JSON"
    echo

    if [[ -z "$RAW_JSON" || "$RAW_JSON" == "null" ]]; then
      echo "\"$PROJECT_ID\",\"$PROJECT_NAME\",\"$CLUSTER_NAME\",\"$DEPT_LABEL\",\"$ENV_LABEL\",\"No maintenance window\"" >> gke_maintenance.log
      continue
    fi

    START_UTC=$(echo "$RAW_JSON" | jq -r '.window.startTime')
    END_UTC=$(echo "$RAW_JSON" | jq -r '.window.endTime')

    START_UTC_HM=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$START_UTC" "+%H:%M")
    END_UTC_HM=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$END_UTC" "+%H:%M")

    START_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$START_UTC" "+%s")
    END_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$END_UTC" "+%s")

    START_TW_HM=$(TZ=Asia/Taipei date -r "$START_EPOCH" "+%H:%M")
    END_TW_HM=$(TZ=Asia/Taipei date -r "$END_EPOCH" "+%H:%M")

    # 英文縮寫 → 中文星期對照表
    WEEK_EN=(MO TU WE TH FR SA SU)
    WEEK_ZH=(一 二 三 四 五 六 日)

    day_to_chinese() {
    for i in "${!WEEK_EN[@]}"; do
        [[ "${WEEK_EN[$i]}" == "$1" ]] && echo -n "${WEEK_ZH[$i]}" && return
    done
    }

    convert_days_to_zh() {
    local input_days=("$@")
    local output=()
    for day in "${input_days[@]}"; do
        output+=( "$(day_to_chinese "$day")" )
    done
    (IFS=, ; echo "${output[*]}")
    }

    # 星期順序表
    DAYS=(MO TU WE TH FR SA SU)

    # 建立轉換對照表（直接 shift）
    get_next_day() {
    for i in "${!DAYS[@]}"; do
        if [[ "${DAYS[$i]}" == "$1" ]]; then
        NEXT_INDEX=$(( (i + 1) % 7 ))
        echo "${DAYS[$NEXT_INDEX]}"
        return
        fi
    done
    }

    # 抓出原始 BYDAY 並處理
    BYDAY=$(echo "$RAW_JSON" | jq -r '.recurrence' | sed -E 's/^FREQ=WEEKLY;BYDAY=//')
    IFS=',' read -ra ORIG_DAYS <<< "$BYDAY"

    # 取得 UTC 日期
    START_UTC_DATE=$(date -u -r "$START_EPOCH" "+%Y-%m-%d")

    # 取得台灣日期（用 TZ 轉換）
    START_TW_DATE=$(TZ=Asia/Taipei date -r "$START_EPOCH" "+%Y-%m-%d")

    TW_DAYS=()
    if [[ "$START_UTC_DATE" != "$START_TW_DATE" ]]; then
    # 跨日才 shift 星期
    for day in "${ORIG_DAYS[@]}"; do
        TW_DAYS+=( "$(get_next_day "$day")" )
    done
    else
    # 同一天，不 shift 星期
    for day in "${ORIG_DAYS[@]}"; do
        TW_DAYS+=( "$day" )
    done
    fi

    # 中文轉換
    BYDAY_ZH=$(convert_days_to_zh "${ORIG_DAYS[@]}")
    TW_DAYS_ZH=$(convert_days_to_zh "${TW_DAYS[@]}")

    # 最終輸出（中文 CSV 格式）
    echo "\"$PROJECT_ID\",\"$PROJECT_NAME\",\"$CLUSTER_NAME\",\"$DEPT_LABEL\",\"$ENV_LABEL\",\"$BYDAY_ZH\",\"$START_UTC_HM - $END_UTC_HM\",\"$TW_DAYS_ZH\",\"$START_TW_HM - $END_TW_HM\"" >> gke_maintenance.log
  done <<< "$CLUSTERS"
done