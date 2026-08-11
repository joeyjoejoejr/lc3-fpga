`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_interrupt_tb;
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;
  logic [15:0] psr;

  logic        irq_pending;
  logic [2:0]  irq_priority;
  logic [7:0]  irq_vector;

  integer cycle;
  logic saw_handler;
  logic saw_return;
  logic saw_resume;
  logic saw_low_handler;
  logic saw_low_return;
  logic saw_high_handler;
  logic saw_high_return;
  logic requested_high;
  logic requested_lower;

  localparam logic [15:0] START_PC       = 16'h3000;
  localparam logic [15:0] MASK_PC        = 16'h3100;
  localparam logic [15:0] ISR_PC         = 16'h1000;
  localparam logic [15:0] LOW_ISR_PC     = 16'h1100;
  localparam logic [15:0] HIGH_ISR_PC    = 16'h1200;
  localparam logic [15:0] LOWER_ISR_PC   = 16'h1300;
  localparam logic [15:0] USER_START_PC  = 16'h3300;
  localparam logic [15:0] SUP_STACK_INIT = 16'h4000;
  localparam logic [15:0] USER_STACK_INIT = 16'h5000;
  localparam logic [15:0] PARAM_SSP_INIT = 16'h3000;
  localparam logic [15:0] STACKED_PC     = 16'h3FFE;
  localparam logic [15:0] STACKED_PSR    = 16'h3FFF;
  localparam logic [15:0] PARAM_STACKED_PC = 16'h2FFE;
  localparam logic [15:0] PARAM_STACKED_PSR = 16'h2FFF;
  localparam logic [15:0] SUP_PSR_P0_P   = 16'h8001;
  localparam logic [15:0] SUP_PSR_P4_P   = 16'h8401;
  localparam logic [15:0] SUP_PSR_P5_P   = 16'h8501;
  localparam logic [15:0] USER_PSR_P0_P  = 16'h0001;

  always #5 clk = ~clk;

  lc3_core dut (
    .clk(clk),
    .reset(reset),
    .reset_pc(16'h0200),
    .pennsim_privilege_mode(1'b1),
    .machine_halt(1'b0),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir),
    .mpr(16'hFFFF),
    .psr(psr),
    .irq_pending(irq_pending),
    .irq_priority(irq_priority),
    .irq_vector(irq_vector)
  );

  lc3_memory memory (
    .clk(clk),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .wdata(mem_wdata),
    .we(mem_we)
  );

  task automatic reset_core_with_r6(
    input logic [15:0] start_pc,
    input logic [15:0] start_psr,
    input logic [15:0] start_r6
  );
    begin
      irq_pending <= 1'b0;
      irq_priority <= 3'd0;
      irq_vector <= 8'h00;
      reset <= 1'b1;
      repeat (2) @(posedge clk);
      reset <= 1'b0;
      @(negedge clk);
      dut.pc = start_pc;
      dut.psr = start_psr;
      dut.regs[0] = 16'h0000;
      dut.regs[1] = 16'h0000;
      dut.regs[2] = 16'h0000;
      dut.regs[3] = 16'h0000;
      dut.regs[4] = 16'h0000;
      dut.regs[5] = 16'h0000;
      dut.regs[6] = start_r6;
    end
  endtask

  task automatic reset_core_at(
    input logic [15:0] start_pc,
    input logic [15:0] start_psr
  );
    reset_core_with_r6(start_pc, start_psr, SUP_STACK_INIT);
  endtask

  task automatic fail_interrupt(input string message);
    begin
      $display("%s[FAIL]%s %-14s %s", TB_RED, TB_RESET, "interrupt", message);
      $display("       PC=%04h IR=%04h PSR=%04h R0=%04h R1=%04h R2=%04h R3=%04h R4=%04h R5=%04h R6=%04h irq_pending=%0b",
               pc, ir, psr, dut.regs[0], dut.regs[1], dut.regs[2],
               dut.regs[3], dut.regs[4], dut.regs[5], dut.regs[6], irq_pending);
      $display("       stack[%04h]=%04h stack[%04h]=%04h",
               STACKED_PC, memory.mem[STACKED_PC], STACKED_PSR, memory.mem[STACKED_PSR]);
      $display("       stack[%04h]=%04h stack[%04h]=%04h",
               PARAM_STACKED_PC, memory.mem[PARAM_STACKED_PC],
               PARAM_STACKED_PSR, memory.mem[PARAM_STACKED_PSR]);
      $fatal(1);
    end
  endtask

  initial begin
    memory.mem[16'h0180] = ISR_PC;      // keyboard interrupt vector x80
    memory.mem[16'h0181] = HIGH_ISR_PC;
    memory.mem[16'h0182] = LOWER_ISR_PC;

    memory.mem[16'h3000] = 16'h1021;    // ADD R0, R0, #1
    memory.mem[16'h3001] = 16'h1021;    // ADD R0, R0, #1
    memory.mem[16'h3002] = 16'h0FFF;    // BRnzp x3002

    memory.mem[16'h3100] = 16'h14A1;    // ADD R2, R2, #1
    memory.mem[16'h3101] = 16'h14A1;    // ADD R2, R2, #1
    memory.mem[16'h3102] = 16'h0FFF;    // BRnzp x3102

    memory.mem[16'h1000] = 16'h1261;    // ADD R1, R1, #1
    memory.mem[16'h1001] = 16'h8000;    // RTI

    memory.mem[16'h1100] = 16'h1261;    // ADD R1, R1, #1
    memory.mem[16'h1101] = 16'h1261;    // ADD R1, R1, #1
    memory.mem[16'h1102] = 16'h8000;    // RTI

    memory.mem[16'h1200] = 16'h16E1;    // ADD R3, R3, #1
    memory.mem[16'h1201] = 16'h8000;    // RTI

    memory.mem[16'h1300] = 16'h1921;    // ADD R4, R4, #1
    memory.mem[16'h1301] = 16'h8000;    // RTI

    memory.mem[16'h3300] = 16'h1B61;    // ADD R5, R5, #1
    memory.mem[16'h3301] = 16'h0FFF;    // BRnzp x3301
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_interrupt_tb.vcd");
      $dumpvars(0, lc3_interrupt_tb);
    end

    // Case 1: a pending priority-4 keyboard interrupt vectors through x0180,
    // pushes PC/PSR on the supervisor stack, runs the handler, and returns.
    saw_handler = 1'b0;
    saw_return = 1'b0;
    saw_resume = 1'b0;
    reset_core_at(START_PC, SUP_PSR_P0_P);

    irq_priority <= 3'd4;
    irq_vector <= 8'h80;
    irq_pending <= 1'b1;

    for (cycle = 0; cycle < 160; cycle = cycle + 1) begin
      @(posedge clk);

      if (pc == ISR_PC || pc == 16'h1001) begin
        irq_pending <= 1'b0;
        saw_handler = 1'b1;
        if (psr[15] !== 1'b1 || psr[10:8] !== 3'd4) begin
          fail_interrupt("accepted interrupt should enter supervisor priority 4");
        end
      end

      if (!saw_return &&
          dut.regs[1] == 16'h0001 &&
          pc == START_PC &&
          dut.regs[6] == SUP_STACK_INIT) begin
        saw_return = 1'b1;
      end
    end

    if (!saw_handler) fail_interrupt("core never entered interrupt handler");
    if (!saw_return) fail_interrupt("RTI did not return to saved PC/R6");

    if (memory.mem[STACKED_PC] !== START_PC ||
        memory.mem[STACKED_PSR] !== SUP_PSR_P0_P) begin
      fail_interrupt("interrupt stack frame should be MEM[R6-2]=PC, MEM[R6-1]=PSR");
    end

    // Let the restored program execute after RTI. The core may already have
    // advanced past the first restored instruction by the time this loop samples.
    for (cycle = 0; cycle < 40; cycle = cycle + 1) begin
      @(negedge clk);
      if (!saw_resume &&
          dut.regs[0] !== 16'h0000 &&
          pc >= 16'h3001 &&
          pc <= 16'h3003 &&
          dut.regs[1] == 16'h0001 &&
          dut.regs[6] == SUP_STACK_INIT &&
          psr == SUP_PSR_P0_P) begin
        saw_resume = 1'b1;
      end
    end

    if (!saw_resume) begin
      fail_interrupt("program did not resume at the interrupted PC");
    end

    // Case 2: a priority-4 interrupt must not preempt current priority 5.
    reset_core_at(MASK_PC, SUP_PSR_P5_P);

    irq_priority <= 3'd4;
    irq_vector <= 8'h80;
    irq_pending <= 1'b1;

    for (cycle = 0; cycle < 80; cycle = cycle + 1) begin
      @(posedge clk);
      if (pc == ISR_PC || pc == 16'h1001 || dut.regs[1] !== 16'h0000) begin
        fail_interrupt("lower-priority interrupt entered handler");
      end
    end

    if (dut.regs[2] == 16'h0000) begin
      fail_interrupt("priority masking case did not execute foreground code");
    end

    // Case 3: an equal-priority interrupt must not preempt.
    reset_core_at(MASK_PC, SUP_PSR_P4_P);

    irq_priority <= 3'd4;
    irq_vector <= 8'h80;
    irq_pending <= 1'b1;

    for (cycle = 0; cycle < 80; cycle = cycle + 1) begin
      @(negedge clk);
      if (pc == ISR_PC || pc == 16'h1001 || dut.regs[1] !== 16'h0000) begin
        fail_interrupt("equal-priority interrupt entered handler");
      end
    end

    if (dut.regs[2] == 16'h0000) begin
      fail_interrupt("equal-priority masking case did not execute foreground code");
    end

    // Case 4: a lower-priority interrupt pending during an ISR waits until RTI
    // restores a low enough priority.
    saw_handler = 1'b0;
    saw_return = 1'b0;
    saw_low_handler = 1'b0;
    saw_low_return = 1'b0;
    requested_lower = 1'b0;
    reset_core_at(START_PC, SUP_PSR_P0_P);

    irq_priority <= 3'd4;
    irq_vector <= 8'h80;
    irq_pending <= 1'b1;

    for (cycle = 0; cycle < 260; cycle = cycle + 1) begin
      @(negedge clk);

      if (!requested_lower && (pc == ISR_PC || pc == 16'h1001)) begin
        saw_handler = 1'b1;
        requested_lower = 1'b1;
        irq_priority <= 3'd3;
        irq_vector <= 8'h82;
        irq_pending <= 1'b1;
      end

      if (!saw_return &&
          requested_lower &&
          dut.regs[1] == 16'h0001 &&
          pc == START_PC &&
          psr == SUP_PSR_P0_P) begin
        saw_return = 1'b1;
      end

      if (pc == LOWER_ISR_PC || pc == 16'h1301) begin
        if (!saw_return) begin
          fail_interrupt("lower-priority interrupt preempted active handler");
        end
        saw_low_handler = 1'b1;
        irq_pending <= 1'b0;
        if (psr[10:8] !== 3'd3) begin
          fail_interrupt("lower-priority interrupt entered with wrong priority");
        end
      end

      if (!saw_low_return &&
          saw_low_handler &&
          dut.regs[4] == 16'h0001 &&
          pc == START_PC &&
          dut.regs[6] == SUP_STACK_INIT &&
          psr == SUP_PSR_P0_P) begin
        saw_low_return = 1'b1;
      end
    end

    if (!saw_handler) fail_interrupt("initial interrupt handler was not reached");
    if (!saw_return) fail_interrupt("initial interrupt did not return before lower priority service");
    if (!saw_low_handler) fail_interrupt("pending lower-priority interrupt was not eventually serviced");
    if (!saw_low_return) fail_interrupt("lower-priority interrupt did not return cleanly");

    // Case 5: a higher-priority interrupt can preempt a running ISR.
    memory.mem[16'h0180] = LOW_ISR_PC;
    saw_low_handler = 1'b0;
    saw_low_return = 1'b0;
    saw_high_handler = 1'b0;
    saw_high_return = 1'b0;
    requested_high = 1'b0;
    reset_core_at(START_PC, SUP_PSR_P0_P);

    irq_priority <= 3'd4;
    irq_vector <= 8'h80;
    irq_pending <= 1'b1;

    for (cycle = 0; cycle < 320; cycle = cycle + 1) begin
      @(negedge clk);

      if (pc == LOW_ISR_PC || pc == 16'h1101 || pc == 16'h1102) begin
        saw_low_handler = 1'b1;
        if ((!saw_high_handler || saw_high_return) && psr[10:8] !== 3'd4) begin
          fail_interrupt("first handler entered with wrong priority");
        end
      end

      if (!requested_high && dut.regs[1] == 16'h0001 && pc == 16'h1101) begin
        requested_high = 1'b1;
        irq_priority <= 3'd5;
        irq_vector <= 8'h81;
        irq_pending <= 1'b1;
      end

      if (pc == HIGH_ISR_PC || pc == 16'h1201) begin
        saw_high_handler = 1'b1;
        irq_pending <= 1'b0;
        if (psr[10:8] !== 3'd5) begin
          fail_interrupt("nested handler entered with wrong priority");
        end
      end

      if (!saw_high_return &&
          saw_high_handler &&
          dut.regs[3] == 16'h0001 &&
          pc == 16'h1101 &&
          psr == SUP_PSR_P4_P) begin
        saw_high_return = 1'b1;
      end

      if (!saw_low_return &&
          saw_high_return &&
          dut.regs[1] == 16'h0002 &&
          pc == START_PC &&
          dut.regs[6] == SUP_STACK_INIT &&
          psr == SUP_PSR_P0_P) begin
        saw_low_return = 1'b1;
      end
    end

    if (!saw_low_handler) fail_interrupt("first nested interrupt handler was not reached");
    if (!saw_high_handler) fail_interrupt("higher-priority interrupt did not preempt handler");
    if (!saw_high_return) fail_interrupt("nested interrupt did not return to first handler");
    if (!saw_low_return) fail_interrupt("first handler did not return after nested interrupt");

    // Case 6: a user-mode interrupt uses SSP for the frame and restores USP on RTI.
    memory.mem[16'h0180] = ISR_PC;
    saw_handler = 1'b0;
    saw_return = 1'b0;
    saw_resume = 1'b0;
    reset_core_with_r6(USER_START_PC, USER_PSR_P0_P, USER_STACK_INIT);

    irq_priority <= 3'd4;
    irq_vector <= 8'h80;
    irq_pending <= 1'b1;

    for (cycle = 0; cycle < 220; cycle = cycle + 1) begin
      @(negedge clk);

      if (pc == ISR_PC || pc == 16'h1001) begin
        saw_handler = 1'b1;
        irq_pending <= 1'b0;
        if (psr[15] !== 1'b1 || psr[10:8] !== 3'd4) begin
          fail_interrupt("user interrupt should enter supervisor priority 4");
        end
        if (dut.regs[6] !== PARAM_STACKED_PC) begin
          fail_interrupt("user interrupt did not switch to SSP before stacking");
        end
      end

      if (!saw_return &&
          dut.regs[1] == 16'h0001 &&
          pc == USER_START_PC &&
          dut.regs[6] == USER_STACK_INIT &&
          psr == USER_PSR_P0_P) begin
        saw_return = 1'b1;
      end

      if (!saw_resume &&
          saw_return &&
          dut.regs[5] !== 16'h0000 &&
          pc >= 16'h3301 &&
          pc <= 16'h3302 &&
          dut.regs[6] == USER_STACK_INIT &&
          psr == USER_PSR_P0_P) begin
        saw_resume = 1'b1;
      end
    end

    if (!saw_handler) fail_interrupt("user-mode interrupt handler was not reached");
    if (memory.mem[PARAM_STACKED_PC] !== USER_START_PC ||
        memory.mem[PARAM_STACKED_PSR] !== USER_PSR_P0_P) begin
      fail_interrupt("user-mode interrupt frame should be on supervisor stack");
    end
    if (!saw_return) fail_interrupt("RTI did not restore user PC/PSR/USP");
    if (!saw_resume) fail_interrupt("user program did not resume after RTI");

    print_case_pass("interrupt");
    $finish;
  end
endmodule
