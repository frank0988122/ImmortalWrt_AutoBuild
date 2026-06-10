#!/bin/bash

REPOS=(
    "https://github.com/immortalwrt/immortalwrt"
    "https://github.com/immortalwrt/packages"
    "https://github.com/immortalwrt/luci"
)
BRANCH="openwrt-25.12"

# 存储上次检查的 commit ID 的文件
COMMIT_FILE="last_commits.txt"

# 初始化或读取上次的 commit ID
declare -A LAST_COMMITS
if [[ -f "$COMMIT_FILE" ]]; then
    while IFS= read -r line; do
        repo=$(echo "$line" | cut -d' ' -f1)
        commit=$(echo "$line" | cut -d' ' -f2)
        LAST_COMMITS["$repo"]=$commit
    done < "$COMMIT_FILE"
fi

# 检查每个仓库是否有更新
HAS_UPDATE=false
for REPO in "${REPOS[@]}"; do
    echo "检查仓库: $REPO ..."
    # 获取远程分支的最新 commit ID
    LATEST_COMMIT=$(git ls-remote "$REPO" "refs/heads/$BRANCH" | cut -f1)
    if [[ -z "$LATEST_COMMIT" ]]; then
        echo "错误: 无法获取 $REPO 的 commit ID"
        exit 1
    fi

    # 与上次记录的 commit ID 比较
    if [[ "${LAST_COMMITS["$REPO"]}" != "$LATEST_COMMIT" ]]; then
        echo "✅ 检测到更新: $REPO"
        echo "   旧 commit: ${LAST_COMMITS["$REPO"]}"
        echo "   新 commit: $LATEST_COMMIT"
        HAS_UPDATE=true
        # 更新记录
        LAST_COMMITS["$REPO"]="$LATEST_COMMIT"
    else
        echo "✅ 无更新: $REPO"
    fi
done

# 如果有更新，则更新 commit 记录文件并返回成功（触发编译）
if [[ "$HAS_UPDATE" == true ]]; then
    # 写入新的 commit ID
    > "$COMMIT_FILE"  # 清空文件
    for REPO in "${REPOS[@]}"; do
        echo "$REPO ${LAST_COMMITS["$REPO"]}" >> "$COMMIT_FILE"
    done
    echo "🎯 检测到代码更新，需要编译"
    exit 0
else
    echo "⏭️  无代码更新，跳过编译"
    exit 1
fi
