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
FPGA_CST ?= constraints/lc3_lcd.cst
FPGA_RAM_WORDS ?= 12800
FPGA_TEXT_CONSOLE_MODE ?= 0
FPGA_RESET_PC ?= 12288
FPGA_BUILD := sim/fpga
INVADERS_INIT_HEX := programs/top/invaders_with_p3os.hex
INVADERS_RAM_WORDS := 13056
P3OS_OBJ ?= external/LC3Programs/Invaders/p3os.obj
P3OS_RTT_OBJ ?= programs/os/p3os_rtt.obj
INVADERS_FPGA_BUILD := sim/fpga-invaders
ANDME_INIT_HEX := programs/top/andme_with_os.hex
ANDME_FPGA_BUILD := sim/fpga-andme
ANDME_OS_OBJ ?= /Users/josephjackson/src/ECE-109-Pogram-1-main/lc3os.obj
ANDME_OS_RTT_OBJ ?= programs/os/lc3os_rtt.obj
ANDME_OS_RTT_ASM ?= programs/os/lc3os_rtt.asm
ANDME_RESET_PC ?= 512
TX_FPGA_TOP ?= tx_top
TX_FPGA_CST ?= constraints/tx_test.cst
TX_FPGA_BUILD := sim/fpga-tx
ECHO_FPGA_TOP ?= uart_echo_top
ECHO_FPGA_CST ?= constraints/uart_echo.cst
ECHO_FPGA_BUILD := sim/fpga-echo
RX_PROBE_FPGA_TOP ?= uart_rx_probe_top
RX_PROBE_FPGA_CST ?= constraints/uart_rx_probe.cst
RX_PROBE_FPGA_BUILD := sim/fpga-rx-probe
LCD_COLOR_TOP ?= lcd_color_top
LCD_COLOR_CST ?= constraints/lcd_color_demo.cst
LCD_COLOR_BUILD := sim/fpga-lcd-color
LCD_TEXT_CONSOLE_TOP ?= lcd_text_console_top
LCD_TEXT_CONSOLE_CST ?= constraints/lcd_color_demo.cst
LCD_TEXT_CONSOLE_BUILD := sim/fpga-lcd-text-console
IVERILOG_WARNINGS := -Wall -Wimplicit -Wportbind -Wsensitivity-entire-vector -Wsensitivity-entire-array -Winfloop -Wselect-range -Wno-timescale
IVERILOG_FLAGS ?= -g2012 $(IVERILOG_WARNINGS)
PENNSIM_AS := scripts/assemble_with_pennsim.sh
OBJ_TO_HEX := scripts/lc3_obj_to_hex.py
PATCH_OS_RTT := scripts/patch_os_ret_to_rtt.py
FPGA_INIT_HEX ?= programs/top/lc3_uart_echo.hex

RTL := rtl/lc3_core.sv rtl/lc3_memory.sv
TIMER_RTL := rtl/lc3_timer.sv
KEYBOARD_RTL := rtl/lc3_keyboard.sv
MEMCTL_RTL := rtl/lc3_memory_controller.sv $(TIMER_RTL) $(KEYBOARD_RTL)
UART_TX_RTL := rtl/uart_tx.sv
UART_RX_RTL := rtl/uart_rx.sv
TEXT_CONSOLE_RTL := rtl/lc3_text_console.sv
TEXT_RENDERER_RTL := rtl/lc3_text_renderer.sv rtl/lc3_font_rom.sv
DISPLAY_BRIDGE_RTL := rtl/lc3_display_bridge.sv
TOP_RTL := rtl/lc3_top.sv rtl/lc3_core.sv $(MEMCTL_RTL) $(UART_RX_RTL) $(UART_TX_RTL) rtl/gowin_rpll_9mhz.v rtl/lcd_timing.sv rtl/lc3_framebuffer_reader.sv $(DISPLAY_BRIDGE_RTL) $(TEXT_CONSOLE_RTL) $(TEXT_RENDERER_RTL)
TOP_SIM_RTL := rtl/lc3_top.sv rtl/lc3_core.sv $(MEMCTL_RTL) $(UART_RX_RTL) $(UART_TX_RTL) rtl/lcd_timing.sv rtl/lc3_framebuffer_reader.sv $(DISPLAY_BRIDGE_RTL) $(TEXT_CONSOLE_RTL) $(TEXT_RENDERER_RTL)
TX_TOP_RTL := rtl/tx_top.sv $(UART_TX_RTL)
UART_ECHO_TOP_RTL := rtl/uart_echo_top.sv $(UART_RX_RTL) $(UART_TX_RTL)
UART_RX_PROBE_TOP_RTL := rtl/uart_rx_probe_top.sv
LCD_COLOR_RTL := rtl/lcd_color_top.sv rtl/gowin_rpll_9mhz.v rtl/lcd_timing.sv rtl/lcd_color_bars.sv
LCD_TEXT_CONSOLE_RTL := rtl/lcd_text_console_top.sv rtl/gowin_rpll_9mhz.v rtl/lcd_timing.sv $(TEXT_CONSOLE_RTL) $(TEXT_RENDERER_RTL)
FRAMEBUFFER_READER_RTL := $(wildcard rtl/lc3_framebuffer_reader.sv)
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

.PHONY: test test-fetch test-reset-pc test-add test-and test-not test-br test-lea test-ld test-st test-ldr test-str test-jump test-jmp test-ret test-jsr test-jsrr test-jmpt test-rtt test-rti test-privilege-user test-mpr-protection test-ldi test-sti test-trap test-trap-vector test-memory-controller test-mpr test-timer test-keyboard test-framebuffer-reader test-text-console test-text-renderer test-display-bridge test-top test-andme-os test-uart-tx test-uart-rx assemble fpga-tools fpga-bitstream fpga-program fpga-flash invaders-bitstream invaders-program invaders-flash andme-bitstream andme-program andme-flash tx-bitstream tx-program tx-flash echo-bitstream echo-program echo-flash rx-probe-bitstream rx-probe-program rx-probe-flash lcd-color-bitstream lcd-color-program lcd-color-flash lcd-text-console-bitstream lcd-text-console-program lcd-text-console-flash wave clean

test: test-fetch test-reset-pc test-add test-and test-not test-br test-lea test-ld test-st test-ldr test-str test-jmp test-ret test-jsr test-jsrr test-jmpt test-rtt test-rti test-privilege-user test-mpr-protection test-ldi test-sti test-trap test-trap-vector test-memory-controller test-mpr test-timer test-keyboard test-framebuffer-reader test-text-console test-text-renderer test-display-bridge test-top test-andme-os test-uart-tx test-uart-rx

test-fetch: $(BUILD)/lc3_core_tb.vvp
	@$(RUN_VVP) $<

test-reset-pc: $(BUILD)/lc3_reset_pc_tb.vvp
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

test-jmpt: $(BUILD)/lc3_jmpt_tb.vvp
	@$(RUN_VVP) $<

test-rtt: $(BUILD)/lc3_rtt_tb.vvp
	@$(RUN_VVP) $<

test-rti: $(BUILD)/lc3_rti_tb.vvp
	@$(RUN_VVP) $<

test-privilege-user: $(BUILD)/lc3_privilege_user_tb.vvp
	@$(RUN_VVP) $<

test-mpr-protection: $(BUILD)/lc3_mpr_protection_tb.vvp
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

test-mpr: $(BUILD)/lc3_mpr_tb.vvp
	@$(RUN_VVP) $<

test-timer: $(BUILD)/lc3_timer_tb.vvp
	@$(RUN_VVP) $<

test-keyboard: $(BUILD)/lc3_keyboard_tb.vvp
	@$(RUN_VVP) $<

test-framebuffer-reader: $(BUILD)/lc3_framebuffer_reader_tb.vvp
	@$(RUN_VVP) $<

test-text-console: $(BUILD)/lc3_text_console_tb.vvp
	@$(RUN_VVP) $<

test-text-renderer: $(BUILD)/lc3_text_renderer_tb.vvp
	@$(RUN_VVP) $<

test-display-bridge: $(BUILD)/lc3_display_bridge_tb.vvp
	@$(RUN_VVP) $<

test-top: $(BUILD)/lc3_top_tb.vvp $(TOP_HEX)
	@$(RUN_VVP) $<

test-andme-os: $(BUILD)/lc3_andme_os_tb.vvp $(ANDME_INIT_HEX)
	@$(RUN_VVP) $<

test-uart-tx: $(BUILD)/uart_tx_tb.vvp
	@$(RUN_VVP) $<

test-uart-rx: $(BUILD)/uart_rx_tb.vvp
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

invaders-bitstream: $(INVADERS_INIT_HEX)
	$(MAKE) fpga-bitstream FPGA_INIT_HEX=$(INVADERS_INIT_HEX) FPGA_RAM_WORDS=$(INVADERS_RAM_WORDS) FPGA_BUILD=$(INVADERS_FPGA_BUILD)

invaders-program: $(INVADERS_INIT_HEX)
	$(MAKE) fpga-program FPGA_INIT_HEX=$(INVADERS_INIT_HEX) FPGA_RAM_WORDS=$(INVADERS_RAM_WORDS) FPGA_BUILD=$(INVADERS_FPGA_BUILD)

invaders-flash: $(INVADERS_INIT_HEX)
	$(MAKE) fpga-flash FPGA_INIT_HEX=$(INVADERS_INIT_HEX) FPGA_RAM_WORDS=$(INVADERS_RAM_WORDS) FPGA_BUILD=$(INVADERS_FPGA_BUILD)

andme-bitstream: $(ANDME_INIT_HEX)
	$(MAKE) fpga-bitstream FPGA_INIT_HEX=$(ANDME_INIT_HEX) FPGA_RESET_PC=$(ANDME_RESET_PC) FPGA_TEXT_CONSOLE_MODE=1 FPGA_BUILD=$(ANDME_FPGA_BUILD)

andme-program: $(ANDME_INIT_HEX)
	$(MAKE) fpga-program FPGA_INIT_HEX=$(ANDME_INIT_HEX) FPGA_RESET_PC=$(ANDME_RESET_PC) FPGA_TEXT_CONSOLE_MODE=1 FPGA_BUILD=$(ANDME_FPGA_BUILD)

andme-flash: $(ANDME_INIT_HEX)
	$(MAKE) fpga-flash FPGA_INIT_HEX=$(ANDME_INIT_HEX) FPGA_RESET_PC=$(ANDME_RESET_PC) FPGA_TEXT_CONSOLE_MODE=1 FPGA_BUILD=$(ANDME_FPGA_BUILD)

tx-bitstream: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP).fs

tx-program: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

tx-flash: $(TX_FPGA_BUILD)/$(TX_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

echo-bitstream: $(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP).fs

echo-program: $(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

echo-flash: $(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

rx-probe-bitstream: $(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP).fs

rx-probe-program: $(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

rx-probe-flash: $(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

lcd-color-bitstream: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs

lcd-color-program: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

lcd-color-flash: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

lcd-text-console-bitstream: $(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP).fs

lcd-text-console-program: $(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k $<

lcd-text-console-flash: $(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP).fs
	$(OPENFPGALOADER) -b tangnano20k -f $<

$(BUILD)/lc3_core_tb.vvp: $(RTL) tb/lc3_core_tb.sv tb/tb_helpers.svh programs/fetch_smoke.hex
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_core_tb.sv $(RTL)

$(BUILD)/lc3_reset_pc_tb.vvp: $(RTL) tb/lc3_reset_pc_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_reset_pc_tb.sv $(RTL)

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

$(BUILD)/lc3_jmpt_tb.vvp: $(RTL) tb/lc3_jmpt_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_jmpt_tb.sv $(RTL)

$(BUILD)/lc3_rtt_tb.vvp: $(RTL) tb/lc3_rtt_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_rtt_tb.sv $(RTL)

$(BUILD)/lc3_rti_tb.vvp: $(RTL) tb/lc3_rti_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_rti_tb.sv $(RTL)

$(BUILD)/lc3_privilege_user_tb.vvp: $(RTL) tb/lc3_privilege_user_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_privilege_user_tb.sv $(RTL)

$(BUILD)/lc3_mpr_protection_tb.vvp: $(RTL) tb/lc3_mpr_protection_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_mpr_protection_tb.sv $(RTL)

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

$(BUILD)/lc3_mpr_tb.vvp: $(MEMCTL_RTL) tb/lc3_mpr_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_mpr_tb.sv $(MEMCTL_RTL)

$(BUILD)/lc3_timer_tb.vvp: $(MEMCTL_RTL) tb/lc3_timer_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_timer_tb.sv $(MEMCTL_RTL)

$(BUILD)/lc3_keyboard_tb.vvp: $(MEMCTL_RTL) tb/lc3_keyboard_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_keyboard_tb.sv $(MEMCTL_RTL)

$(BUILD)/lc3_framebuffer_reader_tb.vvp: $(MEMCTL_RTL) $(FRAMEBUFFER_READER_RTL) tb/lc3_framebuffer_reader_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_framebuffer_reader_tb.sv $(MEMCTL_RTL) $(FRAMEBUFFER_READER_RTL)

$(BUILD)/lc3_text_console_tb.vvp: $(TEXT_CONSOLE_RTL) tb/lc3_text_console_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -s lc3_text_console_all_tb -o $@ tb/lc3_text_console_tb.sv $(TEXT_CONSOLE_RTL)

$(BUILD)/lc3_text_renderer_tb.vvp: $(TEXT_RENDERER_RTL) tb/lc3_text_renderer_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_text_renderer_tb.sv $(TEXT_RENDERER_RTL)

$(BUILD)/lc3_display_bridge_tb.vvp: $(DISPLAY_BRIDGE_RTL) tb/lc3_display_bridge_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_display_bridge_tb.sv $(DISPLAY_BRIDGE_RTL)

$(BUILD)/lc3_top_tb.vvp: $(TOP_SIM_RTL) tb/lc3_top_tb.sv tb/tb_helpers.svh $(FPGA_INIT_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -DSIMULATION -I tb -o $@ tb/lc3_top_tb.sv $(TOP_SIM_RTL)

$(BUILD)/lc3_andme_os_tb.vvp: rtl/lc3_core.sv $(MEMCTL_RTL) tb/lc3_andme_os_tb.sv tb/tb_helpers.svh $(ANDME_INIT_HEX)
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/lc3_andme_os_tb.sv rtl/lc3_core.sv $(MEMCTL_RTL)

$(BUILD)/uart_tx_tb.vvp: $(UART_TX_RTL) tb/uart_tx_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/uart_tx_tb.sv $(UART_TX_RTL)

$(BUILD)/uart_rx_tb.vvp: $(UART_RX_RTL) tb/uart_rx_tb.sv tb/tb_helpers.svh
	@mkdir -p $(BUILD)
	@$(IVERILOG) $(IVERILOG_FLAGS) -I tb -o $@ tb/uart_rx_tb.sv $(UART_RX_RTL)

programs/top/framebuffer_smoke.hex: scripts/make_framebuffer_smoke_hex.py
	@python3 $<

programs/top/lc3_uart_echo.hex: scripts/make_lc3_uart_echo_hex.py
	@python3 $<

$(P3OS_RTT_OBJ): $(PATCH_OS_RTT) $(P3OS_OBJ)
	@python3 $< $(P3OS_OBJ) $@

programs/top/invaders_with_p3os.hex: scripts/combine_lc3_hex.py $(P3OS_RTT_OBJ) programs/top/invaders.obj
	@python3 $< $@ $(P3OS_RTT_OBJ) programs/top/invaders.obj

programs/top/andme_with_os.hex: scripts/combine_lc3_hex.py $(ANDME_OS_RTT_ASM) $(ANDME_OS_RTT_OBJ) programs/top/andme.obj
	@python3 $< $@ $(ANDME_OS_RTT_OBJ) programs/top/andme.obj

$(FPGA_BUILD)/$(FPGA_TOP).json: $(TOP_RTL) $(TOP_HEX) $(FPGA_INIT_HEX) $(FPGA_CST) | fpga-tools
	@mkdir -p $(FPGA_BUILD)
	$(YOSYS) -p "read_verilog -sv $(TOP_RTL); chparam -set INIT_FILE \"$(FPGA_INIT_HEX)\" -set RESET_PC $(FPGA_RESET_PC) -set RAM_WORDS $(FPGA_RAM_WORDS) -set TEXT_CONSOLE_MODE $(FPGA_TEXT_CONSOLE_MODE) $(FPGA_TOP); synth_gowin -family $(FPGA_FAMILY) -top $(FPGA_TOP) -json $@"

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

$(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP).json: $(UART_ECHO_TOP_RTL) $(ECHO_FPGA_CST) | fpga-tools
	@mkdir -p $(ECHO_FPGA_BUILD)
	$(YOSYS) -p "read_verilog -sv $(UART_ECHO_TOP_RTL); synth_gowin -family $(FPGA_FAMILY) -top $(ECHO_FPGA_TOP) -json $@"

$(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP)_pnr.json: $(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP).json $(ECHO_FPGA_CST) | fpga-tools
	$(NEXTPNR_GOWIN) --json $< --write $@ --device $(FPGA_DEVICE) --vopt family=$(FPGA_PACK_DEVICE) --vopt cst=$(ECHO_FPGA_CST) --freq $(FPGA_FREQ_MHZ)

$(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP).fs: $(ECHO_FPGA_BUILD)/$(ECHO_FPGA_TOP)_pnr.json | fpga-tools
	$(GOWIN_PACK) -d $(FPGA_PACK_DEVICE) -o $@ $<

$(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP).json: $(UART_RX_PROBE_TOP_RTL) $(RX_PROBE_FPGA_CST) | fpga-tools
	@mkdir -p $(RX_PROBE_FPGA_BUILD)
	$(YOSYS) -p "read_verilog -sv $(UART_RX_PROBE_TOP_RTL); synth_gowin -family $(FPGA_FAMILY) -top $(RX_PROBE_FPGA_TOP) -json $@"

$(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP)_pnr.json: $(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP).json $(RX_PROBE_FPGA_CST) | fpga-tools
	$(NEXTPNR_GOWIN) --json $< --write $@ --device $(FPGA_DEVICE) --vopt family=$(FPGA_PACK_DEVICE) --vopt cst=$(RX_PROBE_FPGA_CST) --freq $(FPGA_FREQ_MHZ)

$(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP).fs: $(RX_PROBE_FPGA_BUILD)/$(RX_PROBE_FPGA_TOP)_pnr.json | fpga-tools
	$(GOWIN_PACK) -d $(FPGA_PACK_DEVICE) -o $@ $<

$(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).json: $(LCD_COLOR_RTL) $(LCD_COLOR_CST) | fpga-tools
	@mkdir -p $(LCD_COLOR_BUILD)
	$(YOSYS) -p "read_verilog -sv $(LCD_COLOR_RTL); synth_gowin -family $(FPGA_FAMILY) -top $(LCD_COLOR_TOP) -json $@"

$(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP)_pnr.json: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).json $(LCD_COLOR_CST) | fpga-tools
	$(NEXTPNR_GOWIN) --json $< --write $@ --device $(FPGA_DEVICE) --vopt family=$(FPGA_PACK_DEVICE) --vopt cst=$(LCD_COLOR_CST) --freq $(FPGA_FREQ_MHZ)

$(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP).fs: $(LCD_COLOR_BUILD)/$(LCD_COLOR_TOP)_pnr.json | fpga-tools
	$(GOWIN_PACK) -d $(FPGA_PACK_DEVICE) -o $@ $<

$(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP).json: $(LCD_TEXT_CONSOLE_RTL) $(LCD_TEXT_CONSOLE_CST) | fpga-tools
	@mkdir -p $(LCD_TEXT_CONSOLE_BUILD)
	$(YOSYS) -p "read_verilog -sv $(LCD_TEXT_CONSOLE_RTL); synth_gowin -family $(FPGA_FAMILY) -top $(LCD_TEXT_CONSOLE_TOP) -json $@"

$(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP)_pnr.json: $(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP).json $(LCD_TEXT_CONSOLE_CST) | fpga-tools
	$(NEXTPNR_GOWIN) --json $< --write $@ --device $(FPGA_DEVICE) --vopt family=$(FPGA_PACK_DEVICE) --vopt cst=$(LCD_TEXT_CONSOLE_CST) --freq $(FPGA_FREQ_MHZ)

$(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP).fs: $(LCD_TEXT_CONSOLE_BUILD)/$(LCD_TEXT_CONSOLE_TOP)_pnr.json | fpga-tools
	$(GOWIN_PACK) -d $(FPGA_PACK_DEVICE) -o $@ $<

programs/%.obj: programs/%.asm tools/PennSim.jar
	@$(PENNSIM_AS) $< >/dev/null

programs/%.hex: programs/%.obj
	@$(OBJ_TO_HEX) $< $@

wave: test
	@$(VVP) $(BUILD)/lc3_core_tb.vvp +dump
	@echo "Waveform written to sim/lc3_core_tb.vcd"

clean:
	rm -rf $(BUILD) $(FPGA_BUILD) $(INVADERS_FPGA_BUILD) $(ANDME_FPGA_BUILD) $(TX_FPGA_BUILD) $(ECHO_FPGA_BUILD) $(RX_PROBE_FPGA_BUILD) $(LCD_COLOR_BUILD) $(LCD_TEXT_CONSOLE_BUILD) sim/*.vcd programs/add/*.obj programs/add/*.sym programs/add/*.hex programs/and/*.obj programs/and/*.sym programs/and/*.hex programs/not/*.obj programs/not/*.sym programs/not/*.hex programs/br/*.obj programs/br/*.sym programs/br/*.hex programs/lea/*.obj programs/lea/*.sym programs/lea/*.hex programs/ld/*.obj programs/ld/*.sym programs/ld/*.hex programs/st/*.obj programs/st/*.sym programs/st/*.hex programs/ldr/*.obj programs/ldr/*.sym programs/ldr/*.hex programs/str/*.obj programs/str/*.sym programs/str/*.hex programs/jump/*.obj programs/jump/*.sym programs/jump/*.hex programs/ldi/*.obj programs/ldi/*.sym programs/ldi/*.hex programs/trap/*.obj programs/trap/*.sym programs/trap/*.hex programs/top/*.obj programs/top/*.sym programs/top/*.hex programs/privilege/*.obj programs/privilege/*.sym programs/privilege/*.hex programs/os/*.obj programs/os/*.sym programs/os/*.hex
