#!/bin/bash

OUTPUT=target/dfu

rm -rf $OUTPUT
rm -rf third_party/tock/boards/nordic/nrf52840_dongle/target
mkdir -p $OUTPUT

#first generate Tock OS 
make -C third_party/tock/boards/nordic/nrf52840_dongle program

#copy the hex
cp third_party/tock/boards/nordic/nrf52840_dongle/target/thumbv7em-none-eabi/release/nrf52840_dongle.hex $OUTPUT/nrf52840_dongle.hex

#then generate the openSK app
board=nrf52840_dongle ./deploy.sh app

# generate hex files, with relocation
/usr/local/bin/bin2hex.py --offset=0x30000 target/tab/padding.bin $OUTPUT/padding.hex
/usr/local/bin/bin2hex.py --offset=0x40000 target/tab/cortex-m4.tbf $OUTPUT/cortex-m4.hex

# merge them into one
/usr/local/bin/hexmerge.py -o $OUTPUT/nrf52840_dongle_all_in_one.hex  $OUTPUT/nrf52840_dongle.hex $OUTPUT/padding.hex $OUTPUT/cortex-m4.hex

# create DFU package
nrfutil pkg generate --hw-version 52 --sd-req 0x00 --application-version 1 --application $OUTPUT/nrf52840_dongle_all_in_one.hex $OUTPUT/nrf52840.zip

# insert the dongle, and make it go into dfu mode
echo "Insert the dongle, make it go into DFU mode..."

# flash the dongle
nrfutil dfu usb-serial -pkg $OUTPUT/nrf52840.zip -p /dev/ttyACM0
