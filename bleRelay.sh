#!/bin/bash
#BLE packet relay for HA
sleep 10

start_ble_relay=true

if [[ ! $(/usr/bin/hcitool devices | grep hci) ]]; then
  echo "HCI adapter is unavailable. Exiting!"
  exit 0
fi

if [[ $start_ble_relay != true ]]; then
  echo "Script is disabled. Exiting!"
    /usr/sbin/rfkill block bluetooth
  exit 0
fi

##settings
#hci adapter, get name by checking "hcitool devices", default should be hci0
hci_adapter="hci0"

#ha connection
haAddressAndPort="192.168.1.1:8123"
hostname="$(hostname)"
readonly haAuthToken=$(/usr/sbin/get_ha_token.sh)
if [ -z $haAuthToken ]; then
  echo "HA token unavailable. Exiting!"
  exit 1
fi

#sensor and service definitions
haStatusSensor="input_boolean.${hostname}_ble_relay_status"
HaStatusUrlOn="http://${haAddressAndPort}/api/services/input_boolean/turn_on"
HaStatusUrlOff="http://${haAddressAndPort}/api/services/input_boolean/turn_off"

#MACs to whitelist
MAC0=AA:AA:AA:AA:AA:AA
MAC1=AA:AA:AA:AA:AA:AB

reportStatusToHa() {
  if [[ "$1" != "on" && "$1" != "off" ]]; then
    return 1
  fi

  if [[ "$1" == "on" ]]; then
    curl -s -o /dev/null --insecure -X POST -H "Authorization: Bearer $haAuthToken" -H "Content-Type: application/json" -d '{"entity_id": "'"$haStatusSensor"'"}' $HaStatusUrlOn
  else
    curl -s -o /dev/null --insecure -X POST -H "Authorization: Bearer $haAuthToken" -H "Content-Type: application/json" -d '{"entity_id": "'"$haStatusSensor"'"}' $HaStatusUrlOff
  fi
}

if [[ $1 == "parse" ]]; then

  packet=""
  next_part=""

  while read packet_part
  do
    if [ "$next_part" ]; then
      if [[ $packet_part =~ ^[0-9a-fA-F]{2}\ [0-9a-fA-F] ]]; then
        packet="$packet $packet_part"
      else
        hci_complete_packet=$(echo "$packet" | tr -d "[:blank:]")
        curl -s -o /dev/null -X POST -H "Authorization: Bearer $haAuthToken" -H "Content-Type: application/json" -d '{"packet": "'"$hci_complete_packet"'"}' http://${haAddressAndPort}/api/services/ble_monitor/parse_data

        hci_complete_packet=""
        next_part=""
        packet=""
      fi
    fi

    if [ ! "$next_part" ]; then
      if [[ $packet_part =~ ^\> ]]; then
        packet=`echo $packet_part | sed 's/^>.\(.*$\)/\1/'`
        next_part=true
      fi
    fi
  done

else

  hcitool lewladd $MAC0

  hcitool -i $hci_adapter lescan --whitelist --duplicates --passive 1>/dev/null &
  reportStatusToHa on
  if [ "$(pidof hcitool)" ]; then
    hcidump -i $hci_adapter --raw obex | $0 parse $1
  fi
  reportStatusToHa off
fi
