`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_ldr_tb;
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
    $readmemh("programs/ldr/ldr_smoke.hex", memory.mem);
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_ldr_tb.vcd");
      $dumpvars(0, lc3_ldr_tb);
    end

    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 200; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (dut.regs[1] !== 16'h1234 ||
            dut.regs[2] !== 16'h8000 ||
            dut.regs[4] !== 16'h8000 ||
            dut.n !== 1'b1 ||
            dut.z !== 1'b0 ||
            dut.p !== 1'b0) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "ldr_smoke");
          $display("       actual   R1=%04h R2=%04h R4=%04h",
                   dut.regs[1], dut.regs[2], dut.regs[4]);
          $display("       expected R1=%04h R2=%04h R4=%04h",
                   16'h1234, 16'h8000, 16'h8000);
          print_cc("actual", dut.n, dut.z, dut.p);
          print_cc("expected", 1'b1, 1'b0, 1'b0);
          $fatal(1);
        end

        print_case_pass("ldr_smoke");
        $finish;
      end
    end

    if (!saw_halt) begin
      $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "ldr_smoke");
      $fatal(1);
    end
  end
endmodule
