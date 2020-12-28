# Note: If the FPGA family, or the package changes then the build commands will have to be updated.
BOARD_PIN_DEFS = cfg/tinyfpga_bx
TARGET_MHZ = 16

out/hardware.bin: tmp/hardware.asc
	icetime -d lp8k -c $(TARGET_MHZ) -m -t -r tmp/hardware.asc out/hardware.bin
	icepack tmp/hardware.asc out/hardware.bin

tmp/hardware.asc: $(BOARD_PIN_DEFS).pcf $(BOARD_PIN_DEFS)_addl_clks.py tmp/hardware.json
	nextpnr-ice40 --lp8k --package cm81 --pcf $(BOARD_PIN_DEFS).pcf --pre-pack $(BOARD_PIN_DEFS)_addl_clks.py --json tmp/hardware.json --asc tmp/hardware.asc

tmp/hardware.blif tmp/hardware.json &: rtl/hardware.v
	yosys -Q -q -l tmp/hardware.log -p 'synth_ice40 -top hardware -blif tmp/hardware.blif -json tmp/hardware.json' $^

build: out/hardware.bin

clean:
	rm -f out/hardware.bin tmp/hardware.{asc,blif,json,log,rpt}

upload: out/hardware.bin
	tinyprog -p out/hardware.bin

.DEFAULT_GOAL := build
.PHONY: build clean upload
