`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_jmpt_tb;
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
    .reset_pc(16'h0200),
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
    memory.mem[16'h0200] = 16'h2E01; // LD R7, USER_CODE_ADDR
    memory.mem[16'h0201] = 16'hC1C1; // JMPT R7
    memory.mem[16'h0202] = 16'h3000; // USER_CODE_ADDR

    memory.mem[16'h3000] = 16'h1265; // ADD R1, R1, #5
    memory.mem[16'h3001] = 16'hD000; // unsupported opcode, used as test halt
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_jmpt_tb.vcd");
      $dumpvars(0, lc3_jmpt_tb);
    end

    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 100; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (ir !== 16'hD000 ||
            pc !== 16'h3002 ||
            dut.regs[1] !== 16'h0005 ||
            dut.regs[7] !== 16'h3000) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "jmpt");
          $display("       actual   PC=%04h IR=%04h R1=%04h R7=%04h",
                   pc, ir, dut.regs[1], dut.regs[7]);
          $display("       expected PC=%04h IR=%04h R1=%04h R7=%04h",
                   16'h3002, 16'hD000, 16'h0005, 16'h3000);
          $fatal(1);
        end

        print_case_pass("jmpt");
        $finish;
      end
    end

    if (!saw_halt) begin
      $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "jmpt");
      $display("       PC=%04h IR=%04h R1=%04h R7=%04h state=%0d",
               pc, ir, dut.regs[1], dut.regs[7], dut.state);
      $fatal(1);
    end
  end
endmodule
