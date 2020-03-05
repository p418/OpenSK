#!/bin/bash

OUTPUT=target/dfu

rm -rf $OUTPUT
mkdir -p $OUTPUT

# generate Tock OS and the openSK app
./deploy.py os --board nrf52840_dongle --dfu
./deploy.py app --opensk --dfu

# merge the hex files into one
/usr/local/bin/hexmerge.py -o $OUTPUT/nrf52840_dongle_all_in_one.hex target/tab/nrf52840_dongle.hex target/tab/padding.hex target/tab/cortex-m4.hex

# create DFU packages
nrfutil pkg generate --hw-version 52 --sd-req 0x00 --application-version 1 --application $OUTPUT/nrf52840_dongle_all_in_one.hex $OUTPUT/opensk.zip > /dev/null
nrfutil pkg generate --hw-version 52 --sd-req 0x00 --application-version 1 --application target/tab/nrf52840_dongle.hex $OUTPUT/tock.zip > /dev/null

# insert the dongle, and make it go into dfu mode
echo "Insert the dongle, make it go into DFU mode..."

# flash the dongle
nrfutil dfu usb-serial -pkg $OUTPUT/opensk.zip -p /dev/ttyACM0

echo "Okay, make it go into DFU mode one more time..."
# flash the dongle again
nrfutil dfu usb-serial -pkg $OUTPUT/tock.zip -p /dev/ttyACM0
