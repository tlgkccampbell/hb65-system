#/usr/bin/sh
stty -F $1 115200
echo -ne '\x14\r\nreset\n' > $1