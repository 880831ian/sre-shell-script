#!/bin/bash

# 定義帳號名稱、key_id 和 access_key 的 array
accounts=(
    "pin-yi (demo) / AccountID"
)
aws_access_key_ids=(
    "<access_key>"
)
aws_secret_access_keys=(
    "<access_secret>"
)

# 檢查是否傳入了參數 -c
if [ "$1" == "-c" ]; then
    # 讀取當前的 aws_access_key_id
    current_key=$(aws configure get aws_access_key_id --profile default)

    # 從陣列中找出對應的帳號名稱
    current_account="Unknown"
    for i in "${!aws_access_key_ids[@]}"; do
        if [[ "${aws_access_key_ids[$i]}" == "$current_key" ]]; then
            current_account="${accounts[$i]}"
            break
        fi
    done

    echo "Current AWS account: $current_account"
    exit 0
fi

# 使用 fzf 讓使用者選擇帳號
selected_account=$(printf "%s\n" "${accounts[@]}" | fzf --prompt="Select AWS Account: ")

# 如果沒有選擇帳號則退出
if [ -z "$selected_account" ]; then
    echo "No account selected."
    exit 1
fi

# 找到選中的帳號索引
index=-1
for i in "${!accounts[@]}"; do
    if [[ "${accounts[$i]}" == "$selected_account" ]]; then
        index=$i
        break
    fi
done

# 如果找到帳號索引，更新 AWS credentials
if [ $index -ge 0 ]; then
    aws_access_key_id=${aws_access_key_ids[$index]}
    aws_secret_access_key=${aws_secret_access_keys[$index]}

    # 更新 ~/.aws/credentials
    aws configure set aws_access_key_id "$aws_access_key_id" --profile default
    aws configure set aws_secret_access_key "$aws_secret_access_key" --profile default

    echo "Switched to AWS account: $selected_account"
else
    echo "Account not found."
fi
