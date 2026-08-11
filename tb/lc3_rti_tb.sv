`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_rti_tb;
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;
  logic [15:0] psr;
  integer      cycle;
  logic        saw_rti_return;

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
    .psr(psr)
  );

  lc3_memory memory (
    .clk(clk),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .wdata(mem_wdata),
    .we(mem_we)
  );

  initial begin
    memory.mem[16'h0200] = 16'h8000; // RTI
    memory.mem[16'h3000] = 16'h1265; // ADD R1, R1, #5
    memory.mem[16'h3001] = 16'h8000; // RTI, illegal from user mode
    memory.mem[16'h3002] = 16'hD000; // unsupported opcode, should not execute

    memory.mem[16'h4000] = 16'h3000; // saved PC
    memory.mem[16'h4001] = 16'h0001; // saved PSR: user mode, P set
    memory.mem[16'h4002] = 16'h5000; // would-be PC if user RTI incorrectly executes
    memory.mem[16'h4003] = 16'h0001; // would-be PSR if user RTI incorrectly executes

    memory.mem[16'h5000] = 16'h14A1; // ADD R2, R2, #1
    memory.mem[16'h5001] = 16'hD000; // unsupported opcode, used to catch bad user RTI
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_rti_tb.vcd");
      $dumpvars(0, lc3_rti_tb);
    end

    saw_rti_return = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    @(posedge clk);
    dut.regs[6] = 16'h4000;

    for (cycle = 0; cycle < 120; cycle = cycle + 1) begin
      @(posedge clk);

      if (pc == 16'h3001 && dut.regs[1] == 16'h0005) begin
        if (ir !== 16'h1265 ||
            dut.regs[6] !== 16'h4002 ||
            psr !== 16'h0001) begin
          $display("%s[FAIL]%s %-14s supervisor RTI should restore PC, PSR, and R6",
                   TB_RED, TB_RESET, "rti");
          $display("       actual   PC=%04h IR=%04h R1=%04h R6=%04h PSR=%04h",
                   pc, ir, dut.regs[1], dut.regs[6], psr);
          $display("       expected PC=3001 IR=1265 R1=0005 R6=4002 PSR=0001");
          $fatal(1);
        end

        saw_rti_return = 1'b1;
      end

      if (dut.halted) begin
        if (!saw_rti_return ||
            ir !== 16'h8000 ||
            pc !== 16'h3002 ||
            dut.regs[1] !== 16'h0005 ||
            dut.regs[6] !== 16'h4002 ||
            dut.regs[2] !== 16'h0000 ||
            psr !== 16'h0001) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "rti");
          $display("       actual   saw_return=%0d PC=%04h IR=%04h R1=%04h R2=%04h R6=%04h PSR=%04h",
                   saw_rti_return, pc, ir, dut.regs[1], dut.regs[2], dut.regs[6], psr);
          $display("       expected saw_return=1 PC=3002 IR=8000 R1=0005 R2=0000 R6=4002 PSR=0001");
          $fatal(1);
        end

        print_case_pass("rti");
        $finish;
      end
    end

    $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "rti");
    $display("       PC=%04h IR=%04h R1=%04h R6=%04h PSR=%04h state=%0d",
             pc, ir, dut.regs[1], dut.regs[6], psr, dut.state);
    $fatal(1);
  end
endmodule
