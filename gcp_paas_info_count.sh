#!/bin/bash

# 設定錯誤日誌與統計檔案
LOG_FILE="gcloud_enable_api_errors.log"
OUTPUT_FILE="gcloud_resource_usage.log"

# 取得所有專案 ID
PROJECTS=($(gcloud projects list --format="value(projectId)"))

# 初始化總和變數
total_memorystore_size=0
total_filestore_size=0
total_sql_cpu=0
total_sql_mem=0
total_sql_disk=0

# 清空輸出檔案
echo "專案ID, Memorystore(GB), Filestore(TB), SQL vCPU, SQL Memory(GB), SQL Disk(GB)" > "$OUTPUT_FILE"

# 逐一掃描每個專案
for project in "${PROJECTS[@]}"; do
    echo "處理專案: $project"

    # 檢查並啟用 Redis API
    echo "檢查並啟用 Redis API (gcloud services enable redis.googleapis.com)..."
    if ! gcloud services enable redis.googleapis.com --project=$project 2>/dev/null; then
        echo "權限不足，無法啟用 Redis API 於專案 $project" >> $LOG_FILE
        echo "跳過專案 $project 的 Redis API 啟用"
    fi

    # 檢查並啟用 Filestore API
    echo "檢查並啟用 Filestore API (gcloud services enable file.googleapis.com)..."
    if ! gcloud services enable file.googleapis.com --project=$project 2>/dev/null; then
        echo "權限不足，無法啟用 Filestore API 於專案 $project" >> $LOG_FILE
        echo "跳過專案 $project 的 Filestore API 啟用"
    fi

    # 檢查並啟用 SQL Admin API
    echo "檢查並啟用 SQL Admin API (gcloud services enable sqladmin.googleapis.com)..."
    if ! gcloud services enable sqladmin.googleapis.com --project=$project 2>/dev/null; then
        echo "權限不足，無法啟用 SQL Admin API 於專案 $project" >> $LOG_FILE
        echo "跳過專案 $project 的 SQL Admin API 啟用"
    fi

    # Memorystore (Redis) 計算
    memorystore_size=$(gcloud redis instances list --format="value(memorySizeGb)" --region=asia-east1 --project=$project)
    memorystore_total=0
    for size in $memorystore_size; do
        memorystore_total=$((memorystore_total + size))
    done
    echo "Memorystore 總計 (GB): $memorystore_total"
    total_memorystore_size=$((total_memorystore_size + memorystore_total))

    # Filestore 計算
    filestore_size=$(gcloud filestore instances list --format="value(fileShares[0].capacityGb)" --region=asia-east1 --project=$project)
    filestore_total=0
    for size in $filestore_size; do
        # 轉換為 TB
        if [ "$size" -ge 1024 ]; then
            size=$((size / 1024))
        fi
        filestore_total=$((filestore_total + size))
    done
    echo "Filestore 總計 (TB): $filestore_total"
    total_filestore_size=$((total_filestore_size + filestore_total))

    # Cloud SQL 計算
    sql_instances=$(gcloud sql instances list --format="value(name,settings.tier,settings.dataDiskSizeGb)" --project=$project)
    sql_cpu=0
    sql_mem=0
    sql_disk=0
    while read -r instance; do
        # 從 tier 中提取 vCPU 和記憶體大小
        tier=$(echo $instance | awk '{print $2}')
        disk_size=$(echo $instance | awk '{print $3}')

        if [ -z "$tier" ]; then
            continue
        fi

        if [[ "$tier" == "db-f1-micro" ]]; then
            cpu=1
            mem=0.6
        elif [[ "$tier" == "db-g1-small" ]]; then
            cpu=1
            mem=1.7
        else
            cpu=$(echo $tier | cut -d'-' -f3)
            mem=$(echo "scale=1; $(echo $tier | cut -d'-' -f4)/1024" | bc)
        fi

        sql_cpu=$((sql_cpu + cpu))
        sql_mem=$(echo "$sql_mem + $mem" | bc)
        sql_disk=$((sql_disk + disk_size))
    done <<< "$sql_instances"

    echo "Cloud SQL 總計 (vCPU): $sql_cpu, (Mem): $sql_mem GB, (Disk): $sql_disk GB"
    total_sql_cpu=$((total_sql_cpu + sql_cpu))
    total_sql_mem=$(echo "$total_sql_mem + $sql_mem" | bc)
    total_sql_disk=$((total_sql_disk + sql_disk))

    # 將資料寫入輸出檔案
    echo "$project, $memorystore_total, $filestore_total, $sql_cpu, $sql_mem, $sql_disk" >> "$OUTPUT_FILE"

    echo -e "=====================================\n"
done

# 顯示所有專案的總和
echo "所有專案 Memorystore 總計 (GB): $total_memorystore_size"
echo "所有專案 Filestore 總計 (TB): $total_filestore_size"
echo "所有專案 Cloud SQL 總計 (vCPU): $total_sql_cpu, (Mem): $total_sql_mem GB, (Disk): $total_sql_disk GB"

# 寫入總計到檔案
echo "總計, $total_memorystore_size, $total_filestore_size, $total_sql_cpu, $total_sql_mem, $total_sql_disk" >> "$OUTPUT_FILE"