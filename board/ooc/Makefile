
PWD = $(shell pwd)
PROJECT_NAME = system

CABLE_NAME ?= "USB-Blaster"

QUARTUS_DIR = quartus
QUARTUS_BIN = cd $(QUARTUS_DIR) && quartus
QUARTUS_SH  = cd $(QUARTUS_DIR) && quartus_sh

all: build

create:
	rm -rf $(QUARTUS_DIR)
	mkdir $(QUARTUS_DIR)
	touch $(QUARTUS_DIR)/$(PROJECT_NAME).qpf
	cp $(PROJECT_NAME).* $(QUARTUS_DIR)

open:
	$(QUARTUS_BIN) $(PROJECT_NAME).qpf &

build: create
	$(QUARTUS_SH) --flow compile $(PROJECT_NAME)
