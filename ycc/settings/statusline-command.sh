#!/usr/bin/env bash
# Claude Code Status Line - Inspired by Starship with Catppuccin Mocha theme

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

user=$(whoami)
if [[ -n "$cwd" ]]; then
    dir=$(basename "$cwd")
else
    dir=$(basename "$(pwd)")
fi

git_info=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        status_indicators=""
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            status_indicators="${status_indicators}!"
        fi
        if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
            status_indicators="${status_indicators}?"
        fi
        if ! git diff-index --cached --quiet HEAD -- 2>/dev/null; then
            status_indicators="${status_indicators}+"
        fi

        if [[ -n "$status_indicators" ]]; then
            git_info=$(printf " \033[2m🌱 %s %s\033[0m" "$branch" "$status_indicators")
        else
            git_info=$(printf " \033[2m🌱 %s\033[0m" "$branch")
        fi
    fi
fi

k8s_info=""
if command -v kubectl >/dev/null 2>&1 && [[ -f ~/.kube/config ]]; then
    context=$(kubectl config current-context 2>/dev/null)
    if [[ -n "$context" ]]; then
        namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
        if [[ -n "$namespace" && "$namespace" != "default" ]]; then
            k8s_info=$(printf " \033[2m󱃾 %s[%s]\033[0m" "$context" "$namespace")
        else
            k8s_info=$(printf " \033[2m󱃾 %s\033[0m" "$context")
        fi
    fi
fi

printf "\033[2m🍎 %s \033[0m\033[2m📁 %s\033[0m%s%s" "$user" "$dir" "$git_info" "$k8s_info"
