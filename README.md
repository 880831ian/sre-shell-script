# sre-shell-script

### change_aws_account.sh

切換多個 IAM User，需要先設定 accounts、aws_access_key_ids、aws_secret_access_keys 三個陣列變數

如果是 SSO 使用者，可以使用 Granted，可以參考 [手動切 AWS Profile 太麻煩？試試 Granted，多帳號管理神器助你效率倍增！](https://pin-yi.me/blog/aws/aws-assuming-roles-tool-introduce/)

<br>

### change_gcp_account.sh

切換多個 Google GCP 帳號，需要先新增 email_array 以及下方的 case 欄位，並輸入想命名的 configurations 以及設定 default 的 cluster name

cluster 格式是：gke_{PROJECT_ID}\_{ZONE}_{CLUSTER_NAME}

<br>

### delete_namespace.sh

有時候 k8s namespace 刪除不掉，可以使用這個 script 強制刪除 namespace

<br>

### gcp_cluster_count.sh

列出 GCP 權限內可訪問的 GKE Name 以及 Location 清單

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/gcp_cluster_count.webp)

<br>

### gcp_cluster_node_type.sh

列出 GCP 權限內可訪問的 GKE Node Type 清單 (Node 名稱、Node Type、Node 數量[初始設定值])

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/gcp_cluster_node_type.webp)

<br>

### gcp_cluster_version.sh

列出 GCP 權限內可訪問的 GKE 版本清單(目前腳本是列出 1.26、1.27、1.28 版本的 GKE)

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/gcp_cluster_version.webp)

<br>

### gcp_find_ip.sh

可以自定義快速搜尋的 Project ID 或是全部搜尋

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/gcp_find_ip.webp)

<br>

### gcp_org_node_type.sh

列出 GCP 權限內可訪問的 GKE Node Type 清單 (Node 名稱、Node Type、Node 數量[初始設定值])，並且是以 Org 為單位去搜尋

<br>

### gcp_paas_info_count.sh

列出 PaaS 服務資源總和 (Memorystore、Filestore、Cloud SQL)

<br>

### gcp_ssd_disk_count.sh

列出 GCP 權限內可訪問的 SSD Disk 數量總和

<br>

### gke_maintenance.sh

列出 GCP 權限內可訪問的 GKE Clusters 維護視窗時間、Cgroup，並匯出 CSV 清單

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/gke_maintenance.webp)

<br>

### image_to_webp.sh

將當下目錄的圖片轉換成 webp 格式，並移除原本的圖片檔案

可以參考：[https://github.com/880831ian/image-to-webp](https://github.com/880831ian/image-to-webp)

兩個腳本相同

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/image_to_webp.webp)

<br>

### ip_info.sh

執行 ip-api.com 的 IP 資訊查詢

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/ip_info.webp)

<br>

### rm_k8s_context.sh

移除沒在使用或是想移除的 k8s context

<br>

### rm_terragrunt_cache.sh

設定 TARGET_DIR 執行路徑，會移除 terragrunt 的快取檔案，包含 .terragrunt-cache 以及 .terraform 資料夾，減少磁碟空間使用

<br>

### ssl_check.sh

使用 openssl 檢查網域的 SSL 到期日

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/ssl_check.webp)

<br>

### stress_test.sh

簡單的壓力測試腳本，可以設定要測試的 domain、HTTP 狀態碼、超時秒數

<br>

![圖片](https://raw.githubusercontent.com/880831ian/sre-shell-script/master/images/stress_test.webp)

<br>
