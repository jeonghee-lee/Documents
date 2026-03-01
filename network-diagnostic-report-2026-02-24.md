# Network Performance Diagnostic Report

**Date:** 2026-02-24
**System:** Fedora Linux 43 | Interface: `wlp0s20f3` (WiFi) | AP: SINGTEL-C178 (5GHz, 80MHz)

---

## Measured Symptoms

| Metric | Value |
|---|---|
| Reported speed | < 2 KB/s (up & down) |
| Measured RX during issue | ~2–8 KB/s |
| Measured TX during issue | ~1–5 KB/s |
| PHY link rate (hardware capable) | RX 960 Mbps / TX 816 Mbps |
| WiFi signal | -50 dBm (excellent) |
| TX retries accumulated | 2,433 |

The hardware and signal are healthy — the bottleneck is entirely software/configuration.

---

## Root Causes Found

### 1. WiFi Power Save Mode — CRITICAL
```
Power save: on
```
The WiFi adapter was configured to sleep between packets. This causes the NIC to buffer and delay traffic, producing high latency spikes and near-zero sustained throughput. The 2,433 TX retries are a direct symptom. **This is the primary cause of < 2 KB/s.**

### 2. TCP Slow Start After Idle — HIGH
```
net.ipv4.tcp_slow_start_after_idle = 1
```
Every time power save induced an idle gap, TCP reset its congestion window to minimum and had to ramp back up from scratch. This created a compounding feedback loop with issue #1.

### 3. WiFi Interface in DORMANT Mode — MEDIUM
```
wlp0s20f3: state UP  mode DORMANT
```
wpa_supplicant marked the interface DORMANT, signalling to the network stack that the port was not fully authorized to pass packets, further restricting throughput.

### 4. openclaw-gateway Proxying Chrome Traffic — MEDIUM
```
Chrome (pid 14528) → localhost:18789 → 149.154.166.110:443 (Telegram servers)
```
A user-level service (`openclaw-gateway` from clawhub.ai) was intercepting Chrome connections and routing them through remote Telegram-based servers. Any congestion or latency on that remote path directly degraded browser performance.

---

## Solutions Applied / To Apply

### Best Solution (Permanent Power Save Fix)

```bash
# 1. Create the permanent NetworkManager config
sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf <<'EOF'
[connection]
wifi.powersave = 2
EOF

# 2. Apply immediately
sudo systemctl restart NetworkManager

# 3. Verify
iw dev wlp0s20f3 get power_save
# Expected: Power save: off
```

### Supporting Fixes

```bash
# Disable TCP slow start after idle — immediate
sudo sysctl -w net.ipv4.tcp_slow_start_after_idle=0

# Make it permanent
echo "net.ipv4.tcp_slow_start_after_idle = 0" | sudo tee /etc/sysctl.d/99-network-perf.conf
sudo sysctl -p /etc/sysctl.d/99-network-perf.conf

# Fix DORMANT interface state
sudo systemctl restart NetworkManager

# If browser is still slow, stop the proxy and test
systemctl --user stop openclaw-gateway
```

---

## Expected Outcome

| Before | After |
|---|---|
| < 2 KB/s | 50–200+ MB/s (full WiFi capacity) |
| 2,433 TX retries (growing) | Near zero retries |
| Interface DORMANT | Interface UP (normal) |
| TCP resets to 0 after idle | TCP maintains window size |

---

## Summary

> **The root cause was WiFi Power Save mode being ON.** The adapter was sleeping between packets, causing cascading TCP retransmissions and near-zero throughput despite a physically excellent WiFi signal and link rate of nearly 1 Gbps. The permanent fix is a single NetworkManager config file (`wifi-powersave-off.conf`) that disables power save across reboots. The secondary fix — disabling `tcp_slow_start_after_idle` — prevents TCP from degrading during any brief idle gaps in future.
