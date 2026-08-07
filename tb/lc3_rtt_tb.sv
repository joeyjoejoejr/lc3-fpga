`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_rtt_tb;
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
    memory.mem[16'h0200] = 16'h2E01; // LD R7, USER_CODE_ADDR
    memory.mem[16'h0201] = 16'hC1C1; // RTT / JMPT R7
    memory.mem[16'h0202] = 16'h3000; // USER_CODE_ADDR

    memory.mem[16'h3000] = 16'h1265; // ADD R1, R1, #5
    memory.mem[16'h3001] = 16'hD000; // unsupported opcode, used as test halt
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_rtt_tb.vcd");
      $dumpvars(0, lc3_rtt_tb);
    end

    repeat (2) @(posedge clk);

    if (psr !== 16'h8002) begin
      $display("%s[FAIL]%s %-14s reset PSR should be supervisor/Z",
               TB_RED, TB_RESET, "rtt");
      $display("       actual   PSR=%04h", psr);
      $display("       expected PSR=%04h", 16'h8002);
      $fatal(1);
    end

    reset <= 1'b0;

    for (cycle = 0; cycle < 100; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        if (ir !== 16'hD000 ||
            pc !== 16'h3002 ||
            dut.regs[1] !== 16'h0005 ||
            dut.regs[7] !== 16'h3000 ||
            psr[15] !== 1'b0 ||
            psr[2:0] !== 3'b001) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "rtt");
          $display("       actual   PC=%04h IR=%04h R1=%04h R7=%04h PSR=%04h",
                   pc, ir, dut.regs[1], dut.regs[7], psr);
          $display("       expected PC=3002 IR=D000 R1=0005 R7=3000 PSR[15]=0 PSR[2:0]=001");
          $fatal(1);
        end

        print_case_pass("rtt");
        $finish;
      end
    end

    $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "rtt");
    $display("       PC=%04h IR=%04h R1=%04h R7=%04h PSR=%04h state=%0d",
             pc, ir, dut.regs[1], dut.regs[7], psr, dut.state);
    $fatal(1);
  end
endmodule
