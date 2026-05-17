IVERILOG ?= iverilog
VVP ?= vvp

RTL := rtl/lc3_core.sv rtl/lc3_memory.sv
TB := tb/lc3_core_tb.sv
BUILD := sim/build

.PHONY: test wave clean

test: $(BUILD)/lc3_core_tb.vvp
	$(VVP) $<

$(BUILD)/lc3_core_tb.vvp: $(RTL) $(TB) programs/fetch_smoke.hex
	mkdir -p $(BUILD)
	$(IVERILOG) -g2012 -Wall -o $@ $(TB) $(RTL)

wave: test
	@echo "Waveform written to sim/lc3_core_tb.vcd"

clean:
	rm -rf $(BUILD) sim/*.vcd
