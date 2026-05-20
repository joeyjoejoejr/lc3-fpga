`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_trap_tb;
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
    $readmemh("programs/trap/trap_halt.hex", memory.mem);
    memory.mem[16'h0025] = 16'h3001;
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_trap_tb.vcd");
      $dumpvars(0, lc3_trap_tb);
    end

    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 50; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (ir !== 16'hD000 || dut.regs[7] !== 16'h3001) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "trap_halt");
          $display("       actual   IR=%04h R7=%04h", ir, dut.regs[7]);
          $display("       expected IR=%04h R7=%04h", 16'hD000, 16'h3001);
          $fatal(1);
        end

        print_case_pass("trap_halt");
        $finish;
      end
    end

    if (!saw_halt) begin
      $display("%s[FAIL]%s %-14s CPU did not halt", TB_RED, TB_RESET, "trap_halt");
      $fatal(1);
    end
  end
endmodule

module lc3_trap_vector_tb;
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;
  integer      cycle;

  always #5 clk = ~clk;

  lc3_core dut (
    .clk(clk),
    .reset(reset),
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
    $readmemh("programs/trap/trap_vector.hex", memory.mem);
    memory.mem[16'h0040] = 16'h3004;
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_trap_vector_tb.vcd");
      $dumpvars(0, lc3_trap_vector_tb);
    end

    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 120; cycle = cycle + 1) begin
      @(posedge clk);

      if (dut.halted) begin
        $display("%s[FAIL]%s %-14s CPU halted instead of following trap vector",
                 TB_RED, TB_RESET, "trap_vector");
        $display("       actual   PC=%04h IR=%04h R1=%04h R2=%04h R3=%04h R7=%04h",
                 pc, ir, dut.regs[1], dut.regs[2], dut.regs[3], dut.regs[7]);
        $display("       expected trap to save R7=3002, jump to 3004, return, then loop at 3003");
        $fatal(1);
      end

      if (pc == 16'h3003 && dut.regs[2] == 16'h0002) begin
        if (dut.regs[1] !== 16'h0001 ||
            dut.regs[3] !== 16'h0003 ||
            dut.regs[7] !== 16'h3002 ||
            dut.n !== 1'b0 ||
            dut.z !== 1'b0 ||
            dut.p !== 1'b1) begin
          $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "trap_vector");
          $display("       actual   R1=%04h R2=%04h R3=%04h R7=%04h",
                   dut.regs[1], dut.regs[2], dut.regs[3], dut.regs[7]);
          $display("       expected R1=%04h R2=%04h R3=%04h R7=%04h",
                   16'h0001, 16'h0002, 16'h0003, 16'h3002);
          print_cc("actual", dut.n, dut.z, dut.p);
          print_cc("expected", 1'b0, 1'b0, 1'b1);
          $fatal(1);
        end

        print_case_pass("trap_vector");
        $finish;
      end
    end

    $display("%s[FAIL]%s %-14s CPU did not reach post-trap loop", TB_RED, TB_RESET, "trap_vector");
    $fatal(1);
  end
endmodule
