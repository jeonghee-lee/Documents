#!/bin/bash
# System Performance Improvements Script
# Run with: bash ~/system-perf-improvements.sh
# Requires sudo — you will be prompted for your password once.

set -e

echo "==> Authenticating sudo..."
sudo -v

echo ""
echo "=== [1/4] NVIDIA Proprietary Driver ==="
echo "Installing akmod-nvidia and CUDA support..."
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
echo "Done. akmods will build the kernel module in the background."
echo "Wait ~5 minutes before rebooting to ensure the module is compiled."

echo ""
echo "=== [2/4] tuned Profile ==="
sudo tuned-adm profile balanced
echo "Active profile: $(tuned-adm active)"

echo ""
echo "=== [3/4] btrfs noatime Mount Options ==="
# Add noatime to the root btrfs entry
sudo sed -i 's|\(subvol=root,compress=zstd:1\)|\1,noatime|' /etc/fstab
# Add noatime to the home btrfs entry
sudo sed -i 's|\(subvol=home,compress=zstd:1\)|\1,noatime|' /etc/fstab

echo "Updated /etc/fstab:"
grep btrfs /etc/fstab

sudo systemctl daemon-reload
sudo mount -o remount /
sudo mount -o remount /home
echo "Remounted / and /home with noatime."

echo ""
echo "=== [4/4] vm.dirty_ratio Tuning ==="
sudo sysctl -w vm.dirty_ratio=20
sudo sysctl -w vm.dirty_background_ratio=5
sudo tee /etc/sysctl.d/99-performance.conf > /dev/null <<'EOF'
vm.dirty_ratio=20
vm.dirty_background_ratio=5
EOF
echo "Kernel parameters applied and persisted to /etc/sysctl.d/99-performance.conf"

echo ""
echo "====================================="
echo "All done. Summary:"
echo "  [1] NVIDIA akmod-nvidia installed — REBOOT REQUIRED (wait ~5 min first)"
echo "  [2] tuned profile set to: balanced"
echo "  [3] btrfs mounts now use noatime"
echo "  [4] vm.dirty_ratio=20, vm.dirty_background_ratio=5 (persistent)"
echo ""
echo "After rebooting, verify NVIDIA driver with: nvidia-smi"
echo "====================================="
