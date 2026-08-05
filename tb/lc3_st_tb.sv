`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_st_tb;
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
    $readmemh("programs/st/st_smoke.hex", memory.mem);
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_st_tb.vcd");
      $dumpvars(0, lc3_st_tb);
    end

    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 150; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (memory.mem[16'h3000] !== 16'hFFFF ||
            memory.mem[16'h3006] !== 16'h0007 ||
            dut.regs[1] !== 16'h0007 ||
            dut.regs[2] !== 16'hFFFF ||
            dut.n !== 1'b1 ||
            dut.z !== 1'b0 ||
            dut.p !== 1'b0) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "st_smoke");
          $display("       actual   mem[3000]=%04h mem[3006]=%04h R1=%04h R2=%04h",
                   memory.mem[16'h3000], memory.mem[16'h3006], dut.regs[1], dut.regs[2]);
          $display("       expected mem[3000]=%04h mem[3006]=%04h R1=%04h R2=%04h",
                   16'hFFFF, 16'h0007, 16'h0007, 16'hFFFF);
          print_cc("actual", dut.n, dut.z, dut.p);
          print_cc("expected", 1'b1, 1'b0, 1'b0);
          $fatal(1);
        end

        print_case_pass("st_smoke");
        $finish;
      end
    end

    if (!saw_halt) begin
      $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "st_smoke");
      $fatal(1);
    end
  end
endmodule
