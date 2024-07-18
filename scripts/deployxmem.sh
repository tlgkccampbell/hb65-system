#/usr/bin/sh
stty -F $2 115200
echo -ne '\x14\r\nprogram 0\n' > $2
sx bin/$1.bin < $2 > $2
echo -ne '\x12' > $2