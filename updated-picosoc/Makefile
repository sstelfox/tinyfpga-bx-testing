hardware.asc: hardware.pcf hardware.blif
	nextpnr-ice40 --lp8k --package cm81 --asc hardware.asc --pcf hardware.pcf --json hardware.json

hardware.bin: hardware.asc
	icetime -d lp8k -c 16 -mtr hardware.rpt hardware.asc
	icepack hardware.asc hardware.bin

# Use a grouped target to generate both of these files
hardware.blif hardware.json &: hardware.v spimemio.v simpleuart.v picosoc.v picorv32.v
	yosys -Q -q -l hardware.log -p 'synth_ice40 -top hardware -blif hardware.blif -json hardware.json' $^

firmware.bin: firmware.elf
	riscv64-linux-gnu-objcopy -O binary firmware.elf firmware.bin

firmware.elf: sections.lds start.S firmware.c
	riscv64-linux-gnu-gcc -march=rv32imc -mabi=ilp32 -nostartfiles \
		-Wl,-Bstatic,-T,sections.lds,--strip-debug,-Map=firmware.map,--cref \
		-ffreestanding -nostdlib -o firmware.elf start.S firmware.c

build: hardware.bin firmware.bin

clean:
	rm -f firmware.{bin,elf,hex,map,o} hardware.{asc,bin,blif,json,log,rpt}

upload: hardware.bin firmware.bin
	tinyprog -p hardware.bin -u firmware.bin

.DEFAULT_GOAL := build
.PHONY: build clean upload
