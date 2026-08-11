`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_privilege_polarity_tb;
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
  logic        saw_user_mode;

  always #5 clk = ~clk;

  lc3_core dut (
    .clk(clk),
    .reset(reset),
    .reset_pc(16'h0200),
    .pennsim_privilege_mode(1'b0),
    .machine_halt(1'b0),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir),
    .mpr(16'h0FF8),
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
    memory.mem[16'h0200] = 16'h2004; // LD R0, SUP_VALUE
    memory.mem[16'h0201] = 16'hB004; // STI R0, PROTECTED_PTR
    memory.mem[16'h0202] = 16'h2E04; // LD R7, USER_START_PTR
    memory.mem[16'h0203] = 16'hC1C1; // JMPT R7
    memory.mem[16'h0204] = 16'hD000; // unsupported opcode, should not execute
    memory.mem[16'h0205] = 16'h1111; // SUP_VALUE
    memory.mem[16'h0206] = 16'h2000; // PROTECTED_PTR
    memory.mem[16'h0207] = 16'h3000; // USER_START_PTR

    memory.mem[16'h3000] = 16'h2003; // LD R0, USER_VALUE
    memory.mem[16'h3001] = 16'hB003; // STI R0, USER_PROTECTED_PTR
    memory.mem[16'h3002] = 16'hD000; // unsupported opcode, should not execute
    memory.mem[16'h3003] = 16'h0000;
    memory.mem[16'h3004] = 16'h2222; // USER_VALUE
    memory.mem[16'h3005] = 16'h2000; // USER_PROTECTED_PTR
    memory.mem[16'h2000] = 16'h0000;
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_privilege_polarity_tb.vcd");
      $dumpvars(0, lc3_privilege_polarity_tb);
    end

    saw_user_mode = 1'b0;
    repeat (2) @(posedge clk);

    if (psr !== 16'h0002) begin
      $display("%s[FAIL]%s %-14s LC3b mode reset PSR should be supervisor/Z",
               TB_RED, TB_RESET, "priv_polarity");
      $display("       actual   PSR=%04h", psr);
      $display("       expected PSR=0002");
      $fatal(1);
    end

    reset <= 1'b0;

    for (cycle = 0; cycle < 120; cycle = cycle + 1) begin
      @(posedge clk);

      if (pc == 16'h3001 && dut.regs[0] == 16'h2222) begin
        if (memory.mem[16'h2000] !== 16'h1111 ||
            psr[15] !== 1'b1 ||
            psr[2:0] !== 3'b001) begin
          $display("%s[FAIL]%s %-14s JMPT should enter LC3b user mode",
                   TB_RED, TB_RESET, "priv_polarity");
          $display("       actual   PC=%04h IR=%04h mem[2000]=%04h PSR=%04h",
                   pc, ir, memory.mem[16'h2000], psr);
          $display("       expected PC=3001 mem[2000]=1111 PSR[15]=1 PSR[2:0]=001");
          $fatal(1);
        end

        saw_user_mode = 1'b1;
      end

      if (dut.halted) begin
        if (!saw_user_mode ||
            pc !== 16'h3002 ||
            ir !== 16'hB003 ||
            memory.mem[16'h2000] !== 16'h1111 ||
            psr[15] !== 1'b1) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "priv_polarity");
          $display("       actual   saw_user=%0d PC=%04h IR=%04h mem[2000]=%04h PSR=%04h",
                   saw_user_mode, pc, ir, memory.mem[16'h2000], psr);
          $display("       expected saw_user=1 PC=3002 IR=B003 mem[2000]=1111 PSR[15]=1");
          $fatal(1);
        end

        print_case_pass("priv_polarity");
        $finish;
      end
    end

    $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "priv_polarity");
    $display("       PC=%04h IR=%04h mem[2000]=%04h PSR=%04h state=%0d",
             pc, ir, memory.mem[16'h2000], psr, dut.state);
    $fatal(1);
  end
endmodule
