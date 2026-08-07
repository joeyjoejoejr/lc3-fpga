`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_privilege_user_tb;
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
  logic        saw_trap_x22;
  logic        saw_rtt_return;

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
    memory.mem[16'h0022] = 16'h3100; // PUTS trap vector, used as generic trap
    memory.mem[16'h0025] = 16'h3101; // HALT trap vector

    memory.mem[16'h0200] = 16'h2E01; // LD R7, USER_CODE_ADDR
    memory.mem[16'h0201] = 16'hC1C1; // JMPT R7
    memory.mem[16'h0202] = 16'h3000; // USER_CODE_ADDR

    memory.mem[16'h3000] = 16'h1265; // ADD R1, R1, #5
    memory.mem[16'h3001] = 16'hF022; // TRAP x22
    memory.mem[16'h3002] = 16'h14A1; // ADD R2, R2, #1
    memory.mem[16'h3003] = 16'hF025; // TRAP x25

    memory.mem[16'h3100] = 16'hC1C1; // RTT R7
    memory.mem[16'h3101] = 16'hD000; // unsupported opcode, used as test halt
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_privilege_user_tb.vcd");
      $dumpvars(0, lc3_privilege_user_tb);
    end

    saw_user_mode = 1'b0;
    saw_trap_x22 = 1'b0;
    saw_rtt_return = 1'b0;
    repeat (2) @(posedge clk);

    if (psr !== 16'h8002) begin
      $display("%s[FAIL]%s %-14s reset PSR should be supervisor/Z",
               TB_RED, TB_RESET, "priv_user");
      $display("       actual   PSR=%04h", psr);
      $display("       expected PSR=%04h", 16'h8002);
      $fatal(1);
    end

    reset <= 1'b0;

    for (cycle = 0; cycle < 120; cycle = cycle + 1) begin
      @(posedge clk);

      if (pc == 16'h3001 && dut.regs[1] == 16'h0005) begin
        if (psr[15] !== 1'b0 || psr[2:0] !== 3'b001) begin
          $display("%s[FAIL]%s %-14s JMPT should enter user mode with P set",
                   TB_RED, TB_RESET, "priv_user");
          $display("       actual   PC=%04h IR=%04h R1=%04h PSR=%04h",
                   pc, ir, dut.regs[1], psr);
          $display("       expected PSR[15]=0 PSR[2:0]=001");
          $fatal(1);
        end

        saw_user_mode = 1'b1;
      end

      if (pc == 16'h3101 && ir == 16'hC1C1) begin
        if (dut.regs[7] !== 16'h3002 ||
            psr[15] !== 1'b1 ||
            psr[2:0] !== 3'b001) begin
          $display("%s[FAIL]%s %-14s TRAP x22 should enter supervisor mode",
                   TB_RED, TB_RESET, "priv_user");
          $display("       actual   PC=%04h IR=%04h R7=%04h PSR=%04h",
                   pc, ir, dut.regs[7], psr);
          $display("       expected PC=3101 IR=C1C1 R7=3002 PSR[15]=1 PSR[2:0]=001");
          $fatal(1);
        end

        saw_trap_x22 = 1'b1;
      end

      if (pc == 16'h3003 && dut.regs[2] == 16'h0001) begin
        if (!saw_trap_x22 ||
            psr[15] !== 1'b0 ||
            psr[2:0] !== 3'b001) begin
          $display("%s[FAIL]%s %-14s RTT should return from TRAP x22 to user mode",
                   TB_RED, TB_RESET, "priv_user");
          $display("       actual   saw_x22=%0d PC=%04h IR=%04h R2=%04h PSR=%04h",
                   saw_trap_x22, pc, ir, dut.regs[2], psr);
          $display("       expected saw_x22=1 PSR[15]=0 PSR[2:0]=001");
          $fatal(1);
        end

        saw_rtt_return = 1'b1;
      end

      if (dut.halted) begin
        if (!saw_user_mode ||
            !saw_trap_x22 ||
            !saw_rtt_return ||
            pc !== 16'h3102 ||
            ir !== 16'hD000 ||
            dut.regs[7] !== 16'h3004 ||
            psr[15] !== 1'b1 ||
            psr[2:0] !== 3'b001) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "priv_user");
          $display("       actual   saw_user=%0d saw_x22=%0d saw_rtt=%0d PC=%04h IR=%04h R7=%04h PSR=%04h",
                   saw_user_mode, saw_trap_x22, saw_rtt_return, pc, ir, dut.regs[7], psr);
          $display("       expected saw_user=1 saw_x22=1 saw_rtt=1 PC=3102 IR=D000 R7=3004 PSR[15]=1 PSR[2:0]=001");
          $fatal(1);
        end

        print_case_pass("priv_user");
        $finish;
      end
    end

    $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "priv_user");
    $display("       PC=%04h IR=%04h R1=%04h R7=%04h PSR=%04h state=%0d",
             pc, ir, dut.regs[1], dut.regs[7], psr, dut.state);
    $fatal(1);
  end
endmodule
