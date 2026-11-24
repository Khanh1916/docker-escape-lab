#!/bin/sh
# Automated verification script for Docker Escape Lab
set -e

echo "=========================================="
echo " Docker Escape Lab - Automated Verification"
echo "=========================================="

echo "\n[+] Checking Vector 1 (Docker Socket)..."
docker exec lab-sock-escape sh -c "
  if [ -S /var/run/docker.sock ]; then
    echo '  [SUCCESS] Docker socket found at /var/run/docker.sock'
    docker ps --format '  - Active container: {{.Names}}'
  else
    echo '  [FAIL] Socket not found'
    exit 1
  fi
"

echo "\n[+] Checking Vector 2 (Privileged Container)..."
docker exec lab-privileged-escape sh -c "
  if ls /dev/sd* 1>/dev/null 2>&1 || ls /dev/nvme* 1>/dev/null 2>&1; then
    echo '  [SUCCESS] Raw host block devices visible in /dev'
  else
    echo '  [FAIL] Host block devices not visible'
    exit 1
  fi
"

echo "\n[+] Checking Vector 3 (Shared Host PID Namespace)..."
docker exec lab-pid-escape sh -c "
  if [ -d /proc/1/root ]; then
    echo '  [SUCCESS] Host PID 1 visible, /proc/1/root accessible'
  else
    echo '  [FAIL] /proc/1/root not accessible'
    exit 1
  fi
"

echo "\n[+] Checking Vector 4 (Sensitive Volume Mount)..."
docker exec lab-volume-escape sh -c "
  if [ -d /host/etc ]; then
    echo '  [SUCCESS] Host filesystem mounted at /host'
  else
    echo '  [FAIL] /host mount not detected'
    exit 1
  fi
"

echo "\n=========================================="
echo " All 4 escape scenarios ready for testing!"
echo "=========================================="
