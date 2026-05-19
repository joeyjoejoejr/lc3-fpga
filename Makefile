IVERILOG ?= iverilog
VVP ?= vvp
RUN_VVP := scripts/run_vvp.sh
IVERILOG_WARNINGS := -Wall -Wimplicit -Wportbind -Wsensitivity-entire-vector -Wsensitivity-entire-array -Winfloop -Wselect-range -Wno-timescale
IVERILOG_FLAGS ?= -g2012 $(IVERILOG_WARNINGS)
PENNSIM_AS := scripts/assemble_with_pennsim.sh
OBJ_TO_HEX := scripts/lc3_obj_to_hex.py

RTL := rtl/lc3_core.sv rtl/lc3_memory.sv
BUILD := sim/build
ADD_ASM := $(wildcard programs/add/*.asm)
ADD_HEX := $(ADD_ASM:.asm=.hex)
AND_ASM := $(wildcard programs/and/*.asm)
AND_HEX := $(AND_ASM:.asm=.hex)
NOT_ASM := $(wildcard programs/not/*.asm)
NOT_HEX := $(NOT_ASM:.asm=.hex)
BR_ASM := $(wildcard programs/br/*.asm)
BR_HEX := $(BR_ASM:.asm=.hex)
LEA_ASM := $(wildcard programs/lea/*.asm)
LEA_HEX := $(LEA_ASM:.asm=.hex)
LD_ASM := $(wildcard programs/ld/*.asm)
LD_HEX := $(LD_ASM:.asm=.hex)
ST_ASM := $(wildcard programs/st/*.asm)
ST_HEX := $(ST_ASM:.asm=.hex)

.PHONY: test test-fetch test-add test-and test-not test-br test-lea test-ld test-st assemble wave clean

test: test-fetch test-add test-and test-not test-br test-lea test-ld test-st

test-fetch: $(BUILD)/lc3_core_tb.vvp
	@$(RUN_VVP) $<

test-add: $(BUILD)/lc3_add_tb.vvp $(ADD_HEX)
	@$(RUN_VVP) $<

test-and: $(BUILD)/lc3_and_tb.vvp $(AND_HEX)
	@$(RUN_VVP) $<

test-not: $(BUILD)/lc3_not_tb.vvp $(NOT_HEX)
	@$(RUN_VVP) $<

test-br: $(BUILD)/lc3_br_tb.vvp $(BR_HEX)
	@$(RUN_VVP) $<

test-lea: $(BUILD)/lc3_lea_tb.vvp $(LEA_HEX)
	@$(RUN_VVP) $<

test-ld: $(BUILD)/lc3_ld_tb.vvp $(LD_HEX)
	@$(RUN_VVP) $<

test-st: $(BUILD)/lc3_st_tb.vvp $(ST_HEX)
	@$(RUN_VVP) $<

assemble: $(ADD_HEX) $(AND_HEX) $(NOT_HEX) $(BR_HEX) $(LEA_HEX) $(LD_HEX) $(ST_HEX)

$(BUILD)/lc3_core_tb.vvp: $(RTL) tb/lc3_core_tb.sv tb/tb_helpers.svh programs/fetch_smoke.hex
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_core_tb.sv $(RTL)

$(BUILD)/lc3_add_tb.vvp: $(RTL) tb/lc3_add_tb.sv tb/tb_helpers.svh $(ADD_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_add_tb.sv $(RTL)

$(BUILD)/lc3_and_tb.vvp: $(RTL) tb/lc3_and_tb.sv tb/tb_helpers.svh $(AND_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_and_tb.sv $(RTL)

$(BUILD)/lc3_not_tb.vvp: $(RTL) tb/lc3_not_tb.sv tb/tb_helpers.svh $(NOT_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_not_tb.sv $(RTL)

$(BUILD)/lc3_br_tb.vvp: $(RTL) tb/lc3_br_tb.sv tb/tb_helpers.svh $(BR_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_br_tb.sv $(RTL)

$(BUILD)/lc3_lea_tb.vvp: $(RTL) tb/lc3_lea_tb.sv tb/tb_helpers.svh $(LEA_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_lea_tb.sv $(RTL)

$(BUILD)/lc3_ld_tb.vvp: $(RTL) tb/lc3_ld_tb.sv tb/tb_helpers.svh $(LD_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_ld_tb.sv $(RTL)

$(BUILD)/lc3_st_tb.vvp: $(RTL) tb/lc3_st_tb.sv tb/tb_helpers.svh $(ST_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_st_tb.sv $(RTL)

programs/%.obj: programs/%.asm tools/PennSim.jar
	@$(PENNSIM_AS) $< >/dev/null

programs/%.hex: programs/%.obj
	@$(OBJ_TO_HEX) $< $@

wave: test
	@$(VVP) $(BUILD)/lc3_core_tb.vvp +dump
	@echo "Waveform written to sim/lc3_core_tb.vcd"

clean:
	rm -rf $(BUILD) sim/*.vcd programs/add/*.obj programs/add/*.sym programs/add/*.hex programs/and/*.obj programs/and/*.sym programs/and/*.hex programs/not/*.obj programs/not/*.sym programs/not/*.hex programs/br/*.obj programs/br/*.sym programs/br/*.hex programs/lea/*.obj programs/lea/*.sym programs/lea/*.hex programs/ld/*.obj programs/ld/*.sym programs/ld/*.hex programs/st/*.obj programs/st/*.sym programs/st/*.hex
