#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -euc

PACKER := $(shell command -v packer 2>/dev/null)

PACKER_WORK_DIR := ./
PACKER_CACHE_DIR := ./packer_cache/
PACKER_HCLOUD_OUT := ./dist/hcloud/wireguard.log
PACKER_DIGITALOCEAN_OUT := ./dist/digitalocean/wireguard.log
PACKER_ORACLE_OUT := ./dist/oracle/wireguard.log
PACKER_QEMU_OUT := ./dist/qemu/wireguard.qcow2

##################################################
## "all" target
##################################################

.PHONY: all
all: build

##################################################
## "build" target
##################################################

.PHONY: build
build: build-qemu

.PHONY: build-hcloud
build-hcloud: $(PACKER_HCLOUD_OUT)

$(PACKER_HCLOUD_OUT):
	mkdir -p '$(dir $(PACKER_HCLOUD_OUT))'
	'$(PACKER)' build -force -only=hcloud.main '$(PACKER_WORK_DIR)' 2>&1 | tee '$(PACKER_HCLOUD_OUT)'

.PHONY: build-digitalocean
build-digitalocean: $(PACKER_DIGITALOCEAN_OUT)

$(PACKER_DIGITALOCEAN_OUT):
	mkdir -p '$(dir $(PACKER_DIGITALOCEAN_OUT))'
	'$(PACKER)' build -force -only=digitalocean.main '$(PACKER_WORK_DIR)' 2>&1 | tee '$(PACKER_DIGITALOCEAN_OUT)'

.PHONY: build-oracle
build-oracle: $(PACKER_ORACLE_OUT)

$(PACKER_ORACLE_OUT):
	mkdir -p '$(dir $(PACKER_ORACLE_OUT))'
	'$(PACKER)' build -force -only=oracle-oci.main '$(PACKER_WORK_DIR)' 2>&1 | tee '$(PACKER_ORACLE_OUT)'

.PHONY: build-qemu
build-qemu: $(PACKER_QEMU_OUT)

$(PACKER_QEMU_OUT):
	mkdir -p '$(dir $(PACKER_QEMU_OUT))'
	'$(PACKER)' build -force -only=qemu.main '$(PACKER_WORK_DIR)'

##################################################
## "clean" target
##################################################

.PHONY: clean
clean:
	rm -rf '$(PACKER_HCLOUD_OUT)' '$(PACKER_DIGITALOCEAN_OUT)' '$(PACKER_ORACLE_OUT)' '$(PACKER_QEMU_OUT)' '$(PACKER_CACHE_DIR)'
