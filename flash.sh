#!/bin/bash

virtualenv .venv
source .venv/bin/activate

pip install -r requirements.txt

make all \
&& read -n 1 -s -r -p "Press any key to continue" \
&& make flash-opensk \
&& read -n 1 -s -r -p "Press any key to continue" \
&& make flash-tock \
&& echo "OK!"

deactivate
make clean
