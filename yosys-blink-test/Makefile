hardware.asc: hardware.pcf hardware.blif
	nextpnr-ice40 --lp8k --package cm81 --asc hardware.asc --pcf hardware.pcf \
		--json hardware.json

hardware.bin: hardware.asc
	icetime -d hx8k -c 12 -mtr hardware.rpt hardware.asc
	icepack hardware.asc hardware.bin

# Use a grouped target to generate both of these files
hardware.blif hardware.json &: hardware.v
	yosys -ql hardware.log -p 'synth_ice40 -top hardware -blif hardware.blif -json hardware.json' $^

build: hardware.bin

clean:
	rm -f hardware.{asc,bin,blif,json,log,rpt}

upload: hardware.bin
	tinyprog -p hardware.bin

.DEFAULT_GOAL := build
.PHONY: build clean upload
