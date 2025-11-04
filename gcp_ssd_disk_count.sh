#!/bin/bash

# 設定錯誤日誌與統計檔案
LOG_FILE="gcloud_enable_api_errors.log"
OUTPUT_FILE="gcloud_resource_usage.log"

# 取得所有專案 ID
PROJECTS=($(gcloud projects list --format="value(projectId)"))

# 初始化總和變數
total_ssd_disk_size=0

# 清空輸出檔案
echo "專案ID, SSD Disk(GB)" > "$OUTPUT_FILE"

# 逐一掃描每個專案
for project in "${PROJECTS[@]}"; do
    echo "處理專案: $project"

    # GCE DISK (SSD) 計算
    ssd_disk_size=$(gcloud compute disks list --filter="type:pd-ssd" --format="value(sizeGb)" --project=$project)
    ssd_total=0
    for size in $ssd_disk_size; do
        ssd_total=$((ssd_total + size))
    done
    echo "SSD 總計 (GB): $ssd_total"
    total_ssd_disk_size=$((total_ssd_disk_size + ssd_total))

    # 將資料寫入輸出檔案
    echo "$project, $ssd_disk_size" >> "$OUTPUT_FILE"

    echo -e "=====================================\n"
done

# 顯示所有專案的總和
echo "所有專案 SSD DISK 總計 (GB): $total_ssd_disk_size"

# 寫入總計到檔案
echo "總計, $total_ssd_disk_size" >> "$OUTPUT_FILE"