#!/bin/bash
set -e
echo "========================================"
echo "   时序人格局 — 一键启动"
echo "========================================"
echo ""
echo "正在启动 Docker 服务..."
docker compose up -d --build
echo ""
echo "等待服务就绪..."
sleep 8
echo ""
echo "----------------------------------------"
echo " 服务已启动！"
echo "----------------------------------------"
echo " Web 应用:   http://localhost:8080"
echo " API 接口:   http://localhost:3030"
echo " 健康检查:   http://localhost:8080/health"
echo "----------------------------------------"
echo ""
read -p "按回车打开浏览器..." -n1
open http://localhost:8080 2>/dev/null || xdg-open http://localhost:8080 2>/dev/null || echo "请手动打开浏览器访问 http://localhost:8080"
