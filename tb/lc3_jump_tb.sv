`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_jump_case #(
  parameter string NAME = "",
  parameter string INIT_FILE = "",
  parameter logic [15:0] EXP_R1 = 16'h0000,
  parameter logic [15:0] EXP_R2 = 16'h0000,
  parameter logic [15:0] EXP_R3 = 16'h0000,
  parameter logic [15:0] EXP_R4 = 16'h0000,
  parameter logic        CHECK_R4 = 1'b0,
  parameter logic [15:0] EXP_R7 = 16'h0000,
  parameter logic        CHECK_R7 = 1'b0,
  parameter logic        EXP_N = 1'b0,
  parameter logic        EXP_Z = 1'b0,
  parameter logic        EXP_P = 1'b1
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

        if (dut.regs[1] !== EXP_R1 ||
            dut.regs[2] !== EXP_R2 ||
            dut.regs[3] !== EXP_R3 ||
            (CHECK_R4 && dut.regs[4] !== EXP_R4) ||
            (CHECK_R7 && dut.regs[7] !== EXP_R7) ||
            dut.psr[2] !== EXP_N ||
            dut.psr[1] !== EXP_Z ||
            dut.psr[0] !== EXP_P) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, NAME);
          $display("       actual   R1=%04h R2=%04h R3=%04h R4=%04h R7=%04h",
                   dut.regs[1], dut.regs[2], dut.regs[3], dut.regs[4], dut.regs[7]);
          $display("       expected R1=%04h R2=%04h R3=%04h R4=%04h%s R7=%04h%s",
                   EXP_R1, EXP_R2, EXP_R3, EXP_R4,
                   CHECK_R4 ? "" : " (ignored)",
                   EXP_R7,
                   CHECK_R7 ? "" : " (ignored)");
          print_cc("actual", dut.psr[2], dut.psr[1], dut.psr[0]);
          print_cc("expected", EXP_N, EXP_Z, EXP_P);
          $fatal(1);
        end

        print_case_pass(NAME);
        cycle = 200;
      end
    end

    if (!saw_halt) begin
      $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, NAME);
      $display("       pc=%04h ir=%04h state=%0d", dut.pc, dut.ir, dut.state);
      $display("       regs     R0=%04h R1=%04h R2=%04h R3=%04h R4=%04h R6=%04h R7=%04h",
               dut.regs[0], dut.regs[1], dut.regs[2], dut.regs[3], dut.regs[4], dut.regs[6], dut.regs[7]);
      $display("       memory   addr=%04h rdata=%04h wdata=%04h we=%0b",
               mem_addr, mem_rdata, mem_wdata, mem_we);
      $fatal(1);
    end
  end
endmodule

module lc3_jump_all_tb;
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_jump_all_tb.vcd");
      $dumpvars(0, lc3_jump_all_tb);
    end

    #5000;
    $display("%s[PASS]%s all jump cases completed", TB_GREEN, TB_RESET);
    $finish;
  end

  lc3_jump_case #(
    .NAME("jmp_smoke"),
    .INIT_FILE("programs/jump/jmp_smoke.hex"),
    .EXP_R1(16'h0000),
    .EXP_R2(16'h0002)
  ) jmp_smoke();

  lc3_jump_case #(
    .NAME("ret_smoke"),
    .INIT_FILE("programs/jump/ret_smoke.hex"),
    .EXP_R1(16'h0001),
    .EXP_R2(16'h0002),
    .EXP_R3(16'h0000)
  ) ret_smoke();

  lc3_jump_case #(
    .NAME("jsr_smoke"),
    .INIT_FILE("programs/jump/jsr_smoke.hex"),
    .EXP_R1(16'h0001),
    .EXP_R2(16'h0002),
    .EXP_R3(16'h0000),
    .EXP_R4(16'h3001),
    .CHECK_R4(1'b1)
  ) jsr_smoke();

  lc3_jump_case #(
    .NAME("jsrr_smoke"),
    .INIT_FILE("programs/jump/jsrr_smoke.hex"),
    .EXP_R1(16'h0001),
    .EXP_R2(16'h0002),
    .EXP_R3(16'h0000),
    .EXP_R4(16'h3002),
    .CHECK_R4(1'b1)
  ) jsrr_smoke();
endmodule

module lc3_jmp_tb;
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_jmp_tb.vcd");
      $dumpvars(0, lc3_jmp_tb);
    end

    #5000;
    $finish;
  end

  lc3_jump_case #(
    .NAME("jmp_smoke"),
    .INIT_FILE("programs/jump/jmp_smoke.hex"),
    .EXP_R1(16'h0000),
    .EXP_R2(16'h0002)
  ) jmp_smoke();
endmodule

module lc3_ret_tb;
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_ret_tb.vcd");
      $dumpvars(0, lc3_ret_tb);
    end

    #5000;
    $finish;
  end

  lc3_jump_case #(
    .NAME("ret_smoke"),
    .INIT_FILE("programs/jump/ret_smoke.hex"),
    .EXP_R1(16'h0001),
    .EXP_R2(16'h0002),
    .EXP_R3(16'h0000)
  ) ret_smoke();
endmodule

module lc3_jsr_tb;
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_jsr_tb.vcd");
      $dumpvars(0, lc3_jsr_tb);
    end

    #5000;
    $finish;
  end

  lc3_jump_case #(
    .NAME("jsr_smoke"),
    .INIT_FILE("programs/jump/jsr_smoke.hex"),
    .EXP_R1(16'h0001),
    .EXP_R2(16'h0002),
    .EXP_R3(16'h0000),
    .EXP_R4(16'h3001),
    .CHECK_R4(1'b1)
  ) jsr_smoke();
endmodule

module lc3_jsrr_tb;
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_jsrr_tb.vcd");
      $dumpvars(0, lc3_jsrr_tb);
    end

    #5000;
    $finish;
  end

  lc3_jump_case #(
    .NAME("jsrr_smoke"),
    .INIT_FILE("programs/jump/jsrr_smoke.hex"),
    .EXP_R1(16'h0001),
    .EXP_R2(16'h0002),
    .EXP_R3(16'h0000),
    .EXP_R4(16'h3002),
    .CHECK_R4(1'b1)
  ) jsrr_smoke();
endmodule
