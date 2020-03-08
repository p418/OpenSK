3RD_PARTY 			:= third_party
OUTPUT				:= target/dfu
NRFUTIL_GENERATE 	:= @nrfutil pkg generate --hw-version 52 --sd-req 0x00 --application-version 1
NRFUTIL_FLASH 		:= @echo "insert key..." && nrfutil dfu usb-serial -t 60

.PHONY: all
all: setup $(OUTPUT)/opensk.zip $(OUTPUT)/tock.zip

.PHONY setup
setup:
	./setup.sh

target/tab/nrf52840_dongle.hex:
	./deploy.py os --board nrf52840_dongle --dfu

target/tab/cortex-m4.hex:
	./deploy.py app --opensk --dfu

$(OUTPUT):
	mkdir -p $(OUTPUT)

$(OUTPUT)/nrf52840_dongle_all_in_one.hex: $(OUTPUT) target/tab/nrf52840_dongle.hex target/tab/cortex-m4.hex
	@hexmerge.py -o $(OUTPUT)/nrf52840_dongle_all_in_one.hex target/tab/nrf52840_dongle.hex target/tab/padding.hex target/tab/cortex-m4.hex

$(OUTPUT)/opensk.zip: $(OUTPUT) $(OUTPUT)/nrf52840_dongle_all_in_one.hex
	$(NRFUTIL_GENERATE) --application $(OUTPUT)/nrf52840_dongle_all_in_one.hex $(OUTPUT)/opensk.zip > /dev/null

$(OUTPUT)/tock.zip: $(OUTPUT) target/tab/nrf52840_dongle.hex
	$(NRFUTIL_GENERATE) --application target/tab/nrf52840_dongle.hex $(OUTPUT)/tock.zip > /dev/null

.PHONY: flash-opensk
flash-opensk:
	$(NRFUTIL_FLASH) -pkg $(OUTPUT)/opensk.zip -p /dev/ttyACM0

.PHONY: flash-tock
flash-tock:
	$(NRFUTIL_FLASH) -pkg $(OUTPUT)/tock.zip -p /dev/ttyACM0


.PHONY: clean
clean:
	@rm -rf $(OUTPUT) $(3RD_PARTY)/tock $(3RD_PARTY)/libtock-rs
	@./reset.sh
