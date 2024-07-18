ifeq ($(OS),Windows_NT)
	WSL = wsl -d Ubuntu --shell-type login
endif

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(notdir $(patsubst %/,%,$(dir $(MAKEFILE_PATH))))

BINDIR=bin
OBJDIR=obj

SRCS = $(wildcard *.asm)
OBJS = $(SRCS:%.asm=$(OBJDIR)/%.o)

all: $(OBJS) | $(BINDIR)
	ld65 $(OBJS) -o $(BINDIR)/$(MAKEFILE_DIR).bin -m $(BINDIR)/$(MAKEFILE_DIR).map -C hb65.cfg

$(OBJDIR):
ifeq ($(OS),Windows_NT)
	@cmd /C "if not exist $(OBJDIR) mkdir $(OBJDIR)"
else
	@mkdir -p $(OBJDIR)
endif

$(BINDIR):
ifeq ($(OS),Windows_NT)
	@cmd /C "if not exist $(BINDIR) mkdir $(BINDIR)"
else
	@mkdir -p $(BINDIR)
endif

$(OBJS): | $(OBJDIR)
$(OBJDIR)/%.o: %.asm
	ca65 -t none -l $(OBJDIR)/$*.lst -o $(OBJDIR)/$*.o $<

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	@rmdir /S /Q $(OBJDIR)
	@rmdir /S /Q $(BINDIR)
else
	@rm -rf $(OBJDIR)
	@rm -rf $(BINDIR)
endif


XMEM_USB_PID ?= 04d8
XMEM_USB_VID ?= 00dd
ifeq ($(OS),Windows_NT)
.PHONY: bindusb
bindusb:
	usbipd bind -i $(XMEM_USB_PID):$(XMEM_USB_VID)

.PHONY: passusb
passusb:
	usbipd attach -a -i $(XMEM_USB_PID):$(XMEM_USB_VID) --wsl
endif

XMEM_PORT ?= /dev/ttyACM0
.PHONY: deployxmem
deployxmem: all
	@$(WSL) ./scripts/deployxmem.sh $(MAKEFILE_DIR) $(XMEM_PORT)

.PHONY: deploy
deploy: deployxmem