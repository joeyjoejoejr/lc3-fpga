`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_reset_pc_tb;
  logic        clk = 1'b0;
  logic        reset = 1'b1;
  logic [15:0] reset_pc = 16'h0200;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;

  always #5 clk = ~clk;

  lc3_core dut (
    .clk(clk),
    .reset(reset),
    .reset_pc(reset_pc),
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
    memory.mem[16'h0200] = 16'h1021; // ADD R0,R0,#1
    memory.mem[16'h3000] = 16'h5020; // AND R0,R0,#0
  end

  task automatic release_reset_and_expect_fetch(
    input logic [15:0] expected_start,
    input logic [15:0] expected_ir
  );
    begin
      repeat (2) @(posedge clk);
      reset <= 1'b0;

      @(posedge clk);
      #1;
      if (mem_addr !== expected_start) begin
        $display("FAIL: expected first fetch from x%04h, got x%04h",
                 expected_start, mem_addr);
        $finish(1);
      end

      repeat (3) @(posedge clk);
      #1;
      if (ir !== expected_ir) begin
        $display("FAIL: expected IR x%04h from reset_pc x%04h, got x%04h",
                 expected_ir, expected_start, ir);
        $finish(1);
      end

      if (pc !== expected_start + 16'd1) begin
        $display("FAIL: expected PC x%04h after fetch, got x%04h",
                 expected_start + 16'd1, pc);
        $finish(1);
      end
    end
  endtask

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_reset_pc_tb.vcd");
      $dumpvars(0, lc3_reset_pc_tb);
    end

    release_reset_and_expect_fetch(16'h0200, 16'h1021);

    reset_pc <= 16'h3000;
    reset <= 1'b1;

    release_reset_and_expect_fetch(16'h3000, 16'h5020);

    $display("%s[PASS]%s %-14s reset_pc selects x0200 and x3000 start addresses",
             TB_GREEN, TB_RESET, "reset_pc");
    $finish;
  end
endmodule
