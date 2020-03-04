#!/bin/bash

OUTPUT=target/dfu

rm -rf $OUTPUT
rm -rf third_party/tock/boards/nordic/nrf52840_dongle/target
mkdir -p $OUTPUT

#first generate Tock OS 
make -C third_party/tock/boards/nordic/nrf52840_dongle program

#copy the hex
cp third_party/tock/boards/nordic/nrf52840_dongle/target/thumbv7em-none-eabi/release/nrf52840_dongle.hex $OUTPUT/tock_os_nrf52840_dongle.hex

#then generate the openSK app
./deploy.py app --opensk

set -e #stop ignoring errors

# generate hex files, with relocation
/usr/local/bin/bin2hex.py --offset=0x30000 target/tab/padding.bin $OUTPUT/padding.hex
/usr/local/bin/bin2hex.py --offset=0x40000 target/tab/cortex-m4.tbf $OUTPUT/app.hex

# merge them into one
/usr/local/bin/hexmerge.py -o $OUTPUT/nrf52840_dongle_all_in_one.hex $OUTPUT/tock_os_nrf52840_dongle.hex $OUTPUT/padding.hex $OUTPUT/app.hex

# create DFU packages
nrfutil pkg generate --hw-version 52 --sd-req 0x00 --application-version 1 --application $OUTPUT/nrf52840_dongle_all_in_one.hex $OUTPUT/opensk.zip > /dev/null
nrfutil pkg generate --hw-version 52 --sd-req 0x00 --application-version 1 --application $OUTPUT/tock_os_nrf52840_dongle.hex $OUTPUT/tock.zip > /dev/null

# insert the dongle, and make it go into dfu mode
echo "Insert the dongle, make it go into DFU mode..."

# flash the dongle
nrfutil dfu usb-serial -pkg $OUTPUT/opensk.zip -p /dev/ttyACM0

echo "Okay, make it go into DFU mode one more time..."
# flash the dongle again
nrfutil dfu usb-serial -pkg $OUTPUT/tock.zip -p /dev/ttyACM0
