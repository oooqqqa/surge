#!/bin/bash

# 测试用法: ./dns_test.sh example.com

# 获取待测试的域名
DOMAIN="$1"

# 检查是否提供了域名参数
if [ -z "$DOMAIN" ]; then
  echo "用法: $0 <domain>"
  exit 1
fi

# 显示当前 DNS 设置（macOS 使用 scutil 查询）
echo "当前 DNS 设置:"
scutil --dns | grep 'nameserver\[[0-9]*\]' | awk '{print $3}' | sort -u

# 使用 macOS 自带的 `dig` 工具进行 DNS 查询
echo
echo "正在查询域名: $DOMAIN"
IPS=$(dig +short "$DOMAIN")

# 检查是否返回了 IP
if [ -z "$IPS" ]; then
  echo "域名解析失败：未返回任何 IP 地址"
else
  echo "域名解析成功，返回 IP："
  echo "$IPS"
fi