IVERILOG ?= iverilog
VVP ?= vvp
RUN_VVP := scripts/run_vvp.sh
YOSYS ?= yosys
OPENFPGALOADER ?= openFPGALoader
FPGA_TOOL_VENV ?= $(HOME)/.local/share/lc3-fpga/fpga-venv
NEXTPNR_GOWIN ?= $(FPGA_TOOL_VENV)/bin/yowasp-nextpnr-himbaechel-gowin
GOWIN_PACK ?= $(FPGA_TOOL_VENV)/bin/gowin_pack
FPGA_TOP ?= lc3_top
FPGA_FAMILY ?= gw2a
FPGA_PACK_DEVICE ?= GW2A-18C
FPGA_DEVICE ?= GW2AR-LV18QN88C8/I7
FPGA_FREQ_MHZ ?= 27
FPGA_CST ?= constraints/tangnano20k.cst
FPGA_BUILD := sim/fpga
TX_FPGA_TOP ?= tx_top
TX_FPGA_CST ?= constraints/tx_test.cst
TX_FPGA_BUILD := sim/fpga-tx
LCD_COLOR_TOP ?= lcd_color_top
LCD_COLOR_CST ?= constraints/lcd_color_demo.cst
LCD_COLOR_BUILD := sim/fpga-lcd-color
IVERILOG_WARNINGS := -Wall -Wimplicit -Wportbind -Wsensitivity-entire-vector -Wsensitivity-entire-array -Winfloop -Wselect-range -Wno-timescale
IVERILOG_FLAGS ?= -g2012 $(IVERILOG_WARNINGS)
PENNSIM_AS := scripts/assemble_with_pennsim.sh
OBJ_TO_HEX := scripts/lc3_obj_to_hex.py

RTL := rtl/lc3_core.sv rtl/lc3_memory.sv
MEMCTL_RTL := rtl/lc3_memory_controller.sv
TOP_RTL := rtl/lc3_top.sv rtl/lc3_core.sv $(MEMCTL_RTL)
UART_TX_RTL := rtl/uart_tx.sv
TX_TOP_RTL := rtl/tx_top.sv $(UART_TX_RTL)
LCD_COLOR_RTL := rtl/lcd_color_top.sv rtl/gowin_rpll_9mhz.v rtl/lcd_timing.sv rtl/lcd_color_bars.sv
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
LDR_ASM := $(wildcard programs/ldr/*.asm)
LDR_HEX := $(LDR_ASM:.asm=.hex)
STR_ASM := $(wildcard programs/str/*.asm)
STR_HEX := $(STR_ASM:.asm=.hex)
JUMP_ASM := $(wildcard programs/jump/*.asm)
JUMP_HEX := $(JUMP_ASM:.asm=.hex)
LDI_ASM := $(wildcard programs/ldi/*.asm)
LDI_HEX := $(LDI_ASM:.asm=.hex)
STI_ASM := $(wildcard programs/sti/*.asm)
STI_HEX := $(STI_ASM:.asm=.hex)
TRAP_ASM := $(wildcard programs/trap/*.asm)
TRAP_HEX := $(TRAP_ASM:.asm=.hex)
TOP_ASM := $(wildcard programs/top/*.asm)
TOP_HEX := $(TOP_ASM:.asm=.hex)

.PHONY: test test-fetch test-add test-and test-not test-br test-lea test-ld test-st test-ldr test-str test-jump test-jmp test-ret test-jsr test-jsrr test-ldi test-sti test-trap test-trap-vector test-memory-controller test-top test-uart-tx assemble fpga-tools fpga-bitstream fpga-program fpga-flash tx-bitstream tx-program tx-flash lcd-color-bitstream lcd-color-program lcd-color-flash wave clean

test: test-fetch test-add test-and test-not test-br test-lea test-ld test-st test-ldr test-str test-jmp test-ret test-jsr test-jsrr test-ldi test-sti test-trap test-trap-vector test-memory-controller test-top

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

test-ldr: $(BUILD)/lc3_ldr_tb.vvp $(LDR_HEX)
	@$(RUN_VVP) $<

test-str: $(BUILD)/lc3_str_tb.vvp $(STR_HEX)
	@$(RUN_VVP) $<

test-jump: $(BUILD)/lc3_jump_tb.vvp $(JUMP_HEX)
	@$(RUN_VVP) $<

test-jmp: $(BUILD)/lc3_jmp_tb.vvp $(JUMP_HEX)
	@$(RUN_VVP) $<

test-ret: $(BUILD)/lc3_ret_tb.vvp $(JUMP_HEX)
	@$(RUN_VVP) $<

test-jsr: $(BUILD)/lc3_jsr_tb.vvp $(JUMP_HEX)
	@$(RUN_VVP) $<

test-jsrr: $(BUILD)/lc3_jsrr_tb.vvp $(JUMP_HEX)
	@$(RUN_VVP) $<

test-ldi: $(BUILD)/lc3_ldi_tb.vvp $(LDI_HEX)
	@$(RUN_VVP) $<

test-sti: $(BUILD)/lc3_sti_tb.vvp $(STI_HEX)
	@$(RUN_VVP) $<

test-trap: $(BUILD)/lc3_trap_tb.vvp $(TRAP_HEX)
	@$(RUN_VVP) $<

test-trap-vector: $(BUILD)/lc3_trap_vector_tb.vvp $(TRAP_HEX)
	@$(RUN_VVP) $<

test-memory-controller: $(BUILD)/lc3_memory_controller_tb.vvp
	@$(RUN_VVP) $<

test-top: $(BUILD)/lc3_top_tb.vvp $(TOP_HEX)
	@$(RUN_VVP) $<

test-uart-tx: $(BUILD)/uart_tx_tb.vvp
	@$(RUN_VVP) $<

assemble: $(ADD_HEX) $(AND_HEX) $(NOT_HEX) $(BR_HEX) $(LEA_HEX) $(LD_HEX) $(ST_HEX) $(LDR_HEX) $(STR_HEX) $(JUMP_HEX) $(LDI_HEX) $(STI_HEX) $(TRAP_HEX) $(TOP_HEX)

fpga-tools:
	@command -v $(YOSYS) >/dev/null || { echo "missing yosys; run: brew install yosys"; exit 1; }
	@command -v $(OPENFPGALOADER) >/dev/null || { echo "missing openFPGALoader; run: brew install openfpgaloader"; exit 1; }
	@test -x "$(NEXTPNR_GOWIN)" || { echo "missing $(NEXTPNR_GOWIN); install yowasp-nextpnr-himbaechel-gowin in $(FPGA_TOOL_VENV)"; exit 1; }
	@test -x "$(GOWIN_PACK)" || { echo "missing $(GOWIN_PACK); install apycula in $(FPGA_TOOL_VENV)"; exit 1; }
	@echo "FPGA tools found"

fpga-bitstream: $(FPGA_BUILD)/$(FPGA_TOP).fs

fpga-program: $(FPGA_BUILD)/$(FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

fpga-flash: $(FPGA_BUILD)/$(FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

tx-bitstream: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP).fs

tx-program: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

tx-flash: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

lcd-color-bitstream: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs

lcd-color-program: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

lcd-color-flash: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

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

$(BUILD)/lc3_ldr_tb.vvp: $(RTL) tb/lc3_ldr_tb.sv tb/tb_helpers.svh $(LDR_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_ldr_tb.sv $(RTL)

$(BUILD)/lc3_str_tb.vvp: $(RTL) tb/lc3_str_tb.sv tb/tb_helpers.svh $(STR_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_str_tb.sv $(RTL)

$(BUILD)/lc3_jump_tb.vvp: $(RTL) tb/lc3_jump_tb.sv tb/tb_helpers.svh $(JUMP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_jump_all_tb -o $@ tb/lc3_jump_tb.sv $(RTL)

$(BUILD)/lc3_jmp_tb.vvp: $(RTL) tb/lc3_jump_tb.sv tb/tb_helpers.svh $(JUMP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_jmp_tb -o $@ tb/lc3_jump_tb.sv $(RTL)

$(BUILD)/lc3_ret_tb.vvp: $(RTL) tb/lc3_jump_tb.sv tb/tb_helpers.svh $(JUMP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_ret_tb -o $@ tb/lc3_jump_tb.sv $(RTL)

$(BUILD)/lc3_jsr_tb.vvp: $(RTL) tb/lc3_jump_tb.sv tb/tb_helpers.svh $(JUMP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_jsr_tb -o $@ tb/lc3_jump_tb.sv $(RTL)

$(BUILD)/lc3_jsrr_tb.vvp: $(RTL) tb/lc3_jump_tb.sv tb/tb_helpers.svh $(JUMP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_jsrr_tb -o $@ tb/lc3_jump_tb.sv $(RTL)

$(BUILD)/lc3_ldi_tb.vvp: $(RTL) tb/lc3_ldi_tb.sv tb/tb_helpers.svh $(LDI_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_ldi_tb.sv $(RTL)

$(BUILD)/lc3_sti_tb.vvp: $(RTL) tb/lc3_sti_tb.sv tb/tb_helpers.svh $(STI_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_sti_tb.sv $(RTL)

$(BUILD)/lc3_trap_tb.vvp: $(RTL) tb/lc3_trap_tb.sv tb/tb_helpers.svh $(TRAP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_trap_tb -o $@ tb/lc3_trap_tb.sv $(RTL)

$(BUILD)/lc3_trap_vector_tb.vvp: $(RTL) tb/lc3_trap_tb.sv tb/tb_helpers.svh $(TRAP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_trap_vector_tb -o $@ tb/lc3_trap_tb.sv $(RTL)

$(BUILD)/lc3_memory_controller_tb.vvp: $(MEMCTL_RTL) tb/lc3_memory_controller_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_memory_controller_tb.sv $(MEMCTL_RTL)

$(BUILD)/lc3_top_tb.vvp: $(TOP_RTL) tb/lc3_top_tb.sv tb/tb_helpers.svh $(TOP_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_top_tb.sv $(TOP_RTL)

$(BUILD)/uart_tx_tb.vvp: $(UART_TX_RTL) tb/uart_tx_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/uart_tx_tb.sv $(UART_TX_RTL)

$(FPGA_BUILD)/$(FPGA_TOP).json: $(TOP_RTL) $(TOP_HEX) $(FPGA_CST) | fpga-tools
	@mkdir -p $(FPGA_BUILD)
	$(YOSYS) -p "read_verilog -sv $(TOP_RTL); synth_gowin -family $(FPGA_FAMILY) -top $(FPGA_TOP) -json $@"

$(FPGA_BUILD)/$(FPGA_TOP)_pnr.json: $(FPGA_BUILD)/$(FPGA_TOP).json $(FPGA_CST) | fpga-tools
	$(NEXTPNR_GOWIN) --json $< --write $@ --device $(FPGA_DEVICE) --vopt family=$(FPGA_PACK_DEVICE) --vopt cst=$(FPGA_CST) --freq $(FPGA_FREQ_MHZ)

$(FPGA_BUILD)/$(FPGA_TOP).fs: $(FPGA_BUILD)/$(FPGA_TOP)_pnr.json | fpga-tools
	$(GOWIN_PACK) -d $(FPGA_PACK_DEVICE) -o $@ $<

$(TX_FPGA_BUILD)/$(TX_FPGA_TOP).json: $(TX_TOP_RTL) $(TX_FPGA_CST) | fpga-tools
	@mkdir -p $(TX_FPGA_BUILD)
	$(YOSYS) -p "read_verilog -sv $(TX_TOP_RTL); synth_gowin -family $(FPGA_FAMILY) -top $(TX_FPGA_TOP) -json $@"

$(TX_FPGA_BUILD)/$(TX_FPGA_TOP)_pnr.json: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP).json $(TX_FPGA_CST) | fpga-tools
	$(NEXTPNR_GOWIN) --json $< --write $@ --device $(FPGA_DEVICE) --vopt family=$(FPGA_PACK_DEVICE) --vopt cst=$(TX_FPGA_CST) --freq $(FPGA_FREQ_MHZ)

$(TX_FPGA_BUILD)/$(TX_FPGA_TOP).fs: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP)_pnr.json | fpga-tools
	$(GOWIN_PACK) -d $(FPGA_PACK_DEVICE) -o $@ $<

$(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).json: $(LCD_COLOR_RTL) $(LCD_COLOR_CST) | fpga-tools
	@mkdir -p $(LCD_COLOR_BUILD)
	$(YOSYS) -p "read_verilog -sv $(LCD_COLOR_RTL); synth_gowin -family $(FPGA_FAMILY) -top $(LCD_COLOR_TOP) -json $@"

$(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP)_pnr.json: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).json $(LCD_COLOR_CST) | fpga-tools
	$(NEXTPNR_GOWIN) --json $< --write $@ --device $(FPGA_DEVICE) --vopt family=$(FPGA_PACK_DEVICE) --vopt cst=$(LCD_COLOR_CST) --freq $(FPGA_FREQ_MHZ)

$(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP)_pnr.json | fpga-tools
	$(GOWIN_PACK) -d $(FPGA_PACK_DEVICE) -o $@ $<

programs/%.obj: programs/%.asm tools/PennSim.jar
	@$(PENNSIM_AS) $< >/dev/null

programs/%.hex: programs/%.obj
	@$(OBJ_TO_HEX) $< $@

wave: test
	@$(VVP) $(BUILD)/lc3_core_tb.vvp +dump
	@echo "Waveform written to sim/lc3_core_tb.vcd"

clean:
	rm -rf $(BUILD) $(FPGA_BUILD) $(TX_FPGA_BUILD) $(LCD_COLOR_BUILD) sim/*.vcd programs/add/*.obj programs/add/*.sym programs/add/*.hex programs/and/*.obj programs/and/*.sym programs/and/*.hex programs/not/*.obj programs/not/*.sym programs/not/*.hex programs/br/*.obj programs/br/*.sym programs/br/*.hex programs/lea/*.obj programs/lea/*.sym programs/lea/*.hex programs/ld/*.obj programs/ld/*.sym programs/ld/*.hex programs/st/*.obj programs/st/*.sym programs/st/*.hex programs/ldr/*.obj programs/ldr/*.sym programs/ldr/*.hex programs/str/*.obj programs/str/*.sym programs/str/*.hex programs/jump/*.obj programs/jump/*.sym programs/jump/*.hex programs/ldi/*.obj programs/ldi/*.sym programs/ldi/*.hex programs/sti/*.obj programs/sti/*.sym programs/sti/*.hex programs/trap/*.obj programs/trap/*.sym programs/trap/*.hex programs/top/*.obj programs/top/*.sym programs/top/*.hex
