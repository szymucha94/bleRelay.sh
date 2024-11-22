#!/bin/bash
sleep 5

/usr/sbin/rfkill unblock bluetooth

sleep 2

if [[ ! $(/usr/bin/hcitool devices | grep hci) ]]; then
  echo "HCI adapter is unavailable. Exiting!"
  exit 0
fi

killall bleRelay.sh
sleep 1
killall hcitool hcidump
sleep 1
echo -e "power off\n" | bluetoothctl
sleep 1
echo -e "power on\n" | bluetoothctl
sleep 1
/root/bleRelay.sh > /dev/null &
sleep 2
