SRCS = \
	hb8b-wozmon.asm

OBJS = $(SRCS:%.asm=%.bin)

all: $(OBJS)

%.bin: %.asm
	ca65 -t none -l $*.lst $<
	ld65 $*.o -o $@ -m $*.map -C hb8b.cfg

