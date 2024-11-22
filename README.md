# bleRelay.sh
PoC bash BLE passive relay script for Home Assistant ble_monitor component

Parses raw packets from hcidump and sends assembled packet lines to Home Assistant via REST API

Successfully running on Raspberry Pi Zero 2W and multiple x86 machines (Dell Venue 8 Pro 5855, Dell Optiplex 7080XE w/ QCA61x4a or Intel AX201 cards). Depends on hcitool and hcidump.

Installation:

1. Install dependencies: hcidump, hcitool, curl. Make sure HA is running ble_monitor component (available via HACS)
2. Modify script settings to match HA address and port, change hci adapter name if required
3. Add MACs of ble devices to the script as variables (check examples). For each device add hcitool lewladd line to the end of script (check "hcitool lewladd $MAC0" line).
Purpose of whitelisting MACs is to prevent high CPU load and unnecessary network traffic due to processing all broadcasting devices in range.
4. Create input_boolean.<hostname>_ble_relay_status helper switch in HA. Or don't - if not needed just comment out "reportStatusToHa on" and "reportStatusToHa off" lines.
5. Run script in background (bleRelay.sh &) as root, check results in HA.

Notes:

1. Script will not recover from adapter crash. For restarts (or even initial start) use bleRelayRestart.sh. Align bleRelay.sh script path inside first.
2. Some devices require active scan to get any usable data. This can be set by removing "--passive" argument from hcitool call. Keep in mind active scan additionally drains battery power from ble devices as it pools for more data on each broadcast.
