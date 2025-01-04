ifeq ($(OS),Windows_NT)
	WSL = wsl -d Ubuntu --shell-type login
endif

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR  := $(notdir $(patsubst %/,%,$(dir $(MAKEFILE_PATH))))

BINDIR=bin
OBJDIR=obj

SRCS = $(wildcard *.asm)
OBJS = $(SRCS:%.asm=$(OBJDIR)/%.o)
DEPS = $(OBJS:%.o=%.d)
BINS = $(BINDIR)/$(MAKEFILE_DIR).bin $(BINDIR)/$(MAKEFILE_DIR).lbl $(BINDIR)/$(MAKEFILE_DIR).map
CFGS = hb65.cfg

ASSM_SYMS = -D EHBASIC_ANSI_SUPPORT -D EHBASIC_MIXED_CASE -D EHBASIC_SKIP_BOOT_PROMPT -D EHBASIC_SKIP_MEMORY_PROMPT -D EHBASIC_CONDENSED_SIGNON
LINK_SYMS = 

all: $(BINS)

$(BINDIR):
ifeq ($(OS),Windows_NT)
	@cmd /C "if not exist $(BINDIR) mkdir $(BINDIR)"
else
	@mkdir -p $(BINDIR)
endif

$(BINS): $(OBJS) | $(BINDIR)
	ld65 $(OBJS) -o $(BINDIR)/$(MAKEFILE_DIR).bin -m $(BINDIR)/$(MAKEFILE_DIR).map -C hb65.cfg -Ln $(BINDIR)/$(MAKEFILE_DIR).lbl $(LINK_SYMS)

$(OBJDIR):
ifeq ($(OS),Windows_NT)
	@cmd /C "if not exist $(OBJDIR) mkdir $(OBJDIR)"
else
	@mkdir -p $(OBJDIR)
endif

$(OBJS): $(CFGS) | $(OBJDIR)
$(OBJDIR)/%.o: %.asm
	ca65 -D hb65 -g -t none --cpu 65C02 -l $(OBJDIR)/$*.lst -o $(OBJDIR)/$*.o --create-dep $(OBJDIR)/$*.d $(ASSM_SYMS) $<

-include $(DEPS)

.PHONY: clean
clean:
ifeq ($(OS),Windows_NT)
	@cmd /c if exist $(OBJDIR) rmdir /S /Q $(OBJDIR)
	@cmd /c if exist $(BINDIR) rmdir /S /Q $(BINDIR)
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