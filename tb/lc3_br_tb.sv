`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_br_case #(
  parameter string NAME = "",
  parameter string INIT_FILE = "",
  parameter logic [15:0] EXP_R0 = 16'h0000,
  parameter logic [15:0] EXP_R1 = 16'h0000,
  parameter logic [15:0] EXP_R2 = 16'h0000,
  parameter logic [15:0] EXP_R3 = 16'h0000,
  parameter logic [15:0] EXP_R4 = 16'h0000,
  parameter logic [15:0] EXP_R5 = 16'h0000,
  parameter logic        EXP_N = 1'b0,
  parameter logic        EXP_Z = 1'b0,
  parameter logic        EXP_P = 1'b0
);
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;
  integer      cycle;
  logic        saw_halt;

  always #5 clk = ~clk;

  lc3_core dut (
    .clk(clk),
    .reset(reset),
    .reset_pc(16'h3000),
    .machine_halt(1'b0),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir),
    .mpr(16'hFFFF)
  );

  lc3_memory memory (
    .clk(clk),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .wdata(mem_wdata),
    .we(mem_we)
  );

  initial begin
    $readmemh(INIT_FILE, memory.mem);
  end

  initial begin
    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 200; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (dut.regs[0] !== EXP_R0 ||
            dut.regs[1] !== EXP_R1 ||
            dut.regs[2] !== EXP_R2 ||
            dut.regs[3] !== EXP_R3 ||
            dut.regs[4] !== EXP_R4 ||
            dut.regs[5] !== EXP_R5 ||
            dut.psr[2] !== EXP_N ||
            dut.psr[1] !== EXP_Z ||
            dut.psr[0] !== EXP_P) begin
          print_case_fail_regs5(
            NAME,
            dut.regs[1], dut.regs[2], dut.regs[3], dut.regs[4], dut.regs[5],
            dut.psr[2], dut.psr[1], dut.psr[0],
            EXP_R1, EXP_R2, EXP_R3, EXP_R4, EXP_R5,
            EXP_N, EXP_Z, EXP_P
          );
          $display("       actual   R0=%04h", dut.regs[0]);
          $display("       expected R0=%04h", EXP_R0);
          $fatal(1);
        end

        print_case_pass(NAME);
        cycle = 200;
      end
    end

    if (!saw_halt) begin
      $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, NAME);
      $fatal(1);
    end
  end
endmodule

module lc3_br_tb;
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_br_tb.vcd");
      $dumpvars(0, lc3_br_tb);
    end
    #5000;
    $display("%s[PASS]%s all BR cases completed", TB_GREEN, TB_RESET);
    $finish;
  end

  lc3_br_case #(
    .NAME("br_smoke"),
    .INIT_FILE("programs/br/br_smoke.hex"),
    .EXP_R0(16'h0001),
    .EXP_R1(16'h0000),
    .EXP_R2(16'h0002),
    .EXP_R3(16'h0003),
    .EXP_R4(16'h0000),
    .EXP_R5(16'hFFFF),
    .EXP_N(1'b1)
  ) br_smoke();

  lc3_br_case #(
    .NAME("br_backward"),
    .INIT_FILE("programs/br/br_backward.hex"),
    .EXP_R0(16'h0000),
    .EXP_R1(16'h0003),
    .EXP_Z(1'b1)
  ) br_backward();
endmodule
