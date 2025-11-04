#!/bin/bash

# 1. 列出所有 contexts
all_contexts=$(kubectl config get-contexts -o name)

# 檢查是否有 context
if [ -z "$all_contexts" ]; then
    echo "沒有找到任何 contexts，腳本終止。"
    exit 1
fi

# 2. 使用 fzf 讓使用者選擇要移除的 contexts
echo "請選擇要移除的 Kubernetes contexts (使用上下鍵選擇，Tab 鍵多選，Enter 確定):"

# 使用 fzf 選擇，可以多選
selected_contexts=$(echo "$all_contexts" | fzf --multi --prompt="選擇 contexts > ")

# 檢查是否選擇了 contexts
if [ -z "$selected_contexts" ]; then
    echo "沒有選擇任何 context，腳本終止。"
    exit 0
fi

# 3. 移除選擇的 contexts、cluster 和 user
echo "以下 contexts 將被移除："
echo "$selected_contexts"

for context in $selected_contexts; do
    echo -e "\n正在移除 context: $context"

    # 獲取 cluster 和 user 名稱
    cluster=$(kubectl config view -o jsonpath="{.contexts[?(@.name=='$context')].context.cluster}")
    user=$(kubectl config view -o jsonpath="{.contexts[?(@.name=='$context')].context.user}")

    # 刪除 context、cluster 和 user
    kubectl config delete-context "$context"
    if [ -n "$cluster" ]; then
        kubectl config delete-cluster "$cluster"
    fi
    if [ -n "$user" ]; then
        kubectl config unset users."$user"
    fi
done

echo -e "\n清理完成！"
