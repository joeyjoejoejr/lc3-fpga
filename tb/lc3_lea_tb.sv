`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_lea_tb;
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
    .ir(ir)
  );

  lc3_memory memory (
    .clk(clk),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .wdata(mem_wdata),
    .we(mem_we)
  );

  initial begin
    $readmemh("programs/lea/lea_smoke.hex", memory.mem);
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_lea_tb.vcd");
      $dumpvars(0, lc3_lea_tb);
    end

    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 100; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (dut.regs[1] !== 16'h3003 ||
            dut.regs[2] !== 16'h3002 ||
            dut.psr[2] !== 1'b0 ||
            dut.psr[1] !== 1'b0 ||
            dut.psr[0] !== 1'b1) begin
          print_case_fail_regs2(
            "lea_smoke",
            dut.regs[1], dut.regs[2],
            dut.psr[2], dut.psr[1], dut.psr[0],
            16'h3003, 16'h3002,
            1'b0, 1'b0, 1'b1
          );
          $fatal(1);
        end

        print_case_pass("lea_smoke");
        $finish;
      end
    end

    if (!saw_halt) begin
      $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "lea_smoke");
      $fatal(1);
    end
  end
endmodule
