#!/bin/bash
# ==============================================================================
# Script Name : setup-nginx.sh
# Description : Thiet lap Nginx Server Block Reverse Proxy va deploy trang tinh
# Author      : Trần Trí Dương (duongtran1702)
# Student ID  : duongtran1702 | Email: duong170226@gmail.com
# Course      : IT209 - Session 07 - Bai tap 4
# ==============================================================================

set -euo pipefail

echo "========================================================================"
echo " [BÀI 4] CẤU HÌNH REVERSE PROXY NGINX CHO ỨNG DỤNG SPRING BOOT"
echo "========================================================================"

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Kịch bản này cần được chạy với quyền root (sudo)." >&2
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_ROOT="/var/www/html"
CONF_SRC="$SCRIPT_DIR/spring-proxy.conf"
CONF_AVAILABLE="/etc/nginx/sites-available/spring-proxy.conf"
CONF_ENABLED="/etc/nginx/sites-enabled/spring-proxy.conf"

# 1. Cài đặt Nginx nếu chưa có
if ! command -v nginx &>/dev/null; then
    echo "[INFO] Đang cài đặt nginx..."
    apt-get update -y && apt-get install -y nginx
fi

# 2. Tạo thư mục trang tĩnh và triển khai index.html
echo "[INFO] Triển khai tệp trang tĩnh index.html vào $WEB_ROOT..."
mkdir -p "$WEB_ROOT"
cp "$SCRIPT_DIR/index.html" "$WEB_ROOT/index.html"
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# 3. Sao chép tệp cấu hình sang sites-available
echo "[INFO] Sao chép tệp cấu hình vào $CONF_AVAILABLE..."
cp "$CONF_SRC" "$CONF_AVAILABLE"

# 4. Kích hoạt Server Block bằng Symlink sang sites-enabled
echo "[INFO] Kích hoạt cấu hình (tạo liên kết mềm sang sites-enabled)..."
if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
    echo "[INFO] Tạm hủy kích hoạt default server block để tránh xung đột..."
    rm -f "/etc/nginx/sites-enabled/default"
fi
ln -sf "$CONF_AVAILABLE" "$CONF_ENABLED"

# 5. Kiểm tra cú pháp Nginx
echo "========================================================================"
echo " [KIỂM TRA CÚ PHÁP NGINX (sudo nginx -t)]"
echo "========================================================================"
nginx -t

# 6. Tải lại dịch vụ Nginx
echo "[INFO] Tải lại cấu hình Nginx..."
systemctl reload nginx || systemctl restart nginx

# 7. Kiểm tra kết nối HTTP qua curl
echo "========================================================================"
echo " [KIỂM THỬ TRUY VẤN HTTP]"
echo "========================================================================"
echo "1. Kiểm tra tiêu đề HTTP trang tĩnh (curl -I http://localhost/):"
curl -I http://localhost/

echo ""
echo "2. Kiểm tra nội dung trang tĩnh (trích xuất thông tin học viên):"
curl -s http://localhost/ | grep -E 'Trần Trí Dương|IT209' || true

echo ""
echo "3. Kiểm tra chuyển tiếp Reverse Proxy tới Spring Boot API (curl -i http://localhost/api/health):"
curl -i http://localhost/api/health || echo "[NOTE] Nếu Spring Boot chưa chạy trên 8082, Nginx sẽ trả về 502. Hãy bật spring-app.service."

echo "========================================================================"
echo "[SUCCESS] Hoàn tất triển khai Nginx Reverse Proxy."
echo "========================================================================"
