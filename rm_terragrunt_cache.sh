#!/bin/bash

TARGET_DIR="<路徑>"

echo "🔍 正在刪除 $TARGET_DIR 下的所有 .terraform.lock.hcl 以及 .terragrunt-cache 資料夾..."

find "$TARGET_DIR" -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;
find "$TARGET_DIR" -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;


echo "✅ 刪除完成"
