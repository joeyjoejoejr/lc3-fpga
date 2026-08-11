`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_mpr_protection_tb;
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] reset_pc;
  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;
  logic [15:0] mpr;
  logic [15:0] psr;
  integer      cycle;
  logic        saw_trap_handler;

  always #5 clk = ~clk;

  lc3_core dut (
    .clk(clk),
    .reset(reset),
    .reset_pc(reset_pc),
    .pennsim_privilege_mode(1'b1),
    .machine_halt(1'b0),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir),
    .mpr(mpr),
    .psr(psr),
    .irq_pending(1'b0),
    .irq_priority(3'd0),
    .irq_vector(8'h00)
  );

  lc3_memory memory (
    .clk(clk),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .wdata(mem_wdata),
    .we(mem_we)
  );

  task automatic start_case(
    input logic [15:0] start_pc,
    input logic        user_mode,
    input logic [15:0] mpr_value
  );
    begin
      reset <= 1'b1;
      reset_pc <= start_pc;
      mpr <= 16'hFFFF;
      repeat (2) @(posedge clk);
      @(negedge clk);
      mpr <= mpr_value;
      reset <= 1'b0;
      dut.psr[15] = user_mode ? 1'b0 : 1'b1;
    end
  endtask

  task automatic wait_for_halt(input string name, input integer max_cycles);
    begin
      for (cycle = 0; cycle < max_cycles; cycle = cycle + 1) begin
        @(posedge clk);
        if (dut.halted) begin
          cycle = max_cycles;
        end
      end

      if (!dut.halted) begin
        $display("%s[FAIL]%s %-14s CPU did not halt",
                 TB_RED, TB_RESET, name);
        $display("       PC=%04h IR=%04h addr=%04h mem_we=%0d PSR=%04h MPR=%04h state=%0d",
                 pc, ir, mem_addr, mem_we, psr, mpr, dut.state);
        $fatal(1);
      end
    end
  endtask

  task automatic expect_fault_halt(
    input string name,
    input logic [15:0] expected_pc,
    input logic [15:0] expected_ir
  );
    begin
      wait_for_halt(name, 80);
      if (pc !== expected_pc || ir !== expected_ir || psr[15] !== 1'b0) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       actual   PC=%04h IR=%04h PSR=%04h MPR=%04h",
                 pc, ir, psr, mpr);
        $display("       expected PC=%04h IR=%04h PSR[15]=0",
                 expected_pc, expected_ir);
        $fatal(1);
      end

      print_case_pass(name);
    end
  endtask

  task automatic run_indirect_store_fault;
    begin
      memory.mem[16'h3000] = 16'h2002; // LD R0, DATA
      memory.mem[16'h3001] = 16'hB002; // STI R0, PROTECTED_TARGET_PTR
      memory.mem[16'h3002] = 16'hD000; // unsupported opcode, should not execute
      memory.mem[16'h3003] = 16'h1234; // DATA
      memory.mem[16'h3004] = 16'h2000; // PROTECTED_TARGET_PTR in allowed page x3
      memory.mem[16'h2000] = 16'h0000;

      start_case(16'h3000, 1'b1, 16'h0FF8);
      wait_for_halt("mpr_sti_fault", 80);

      if (pc !== 16'h3002 ||
          ir !== 16'hB002 ||
          memory.mem[16'h2000] !== 16'h0000 ||
          psr[15] !== 1'b0) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "mpr_sti_fault");
        $display("       actual   PC=%04h IR=%04h mem[2000]=%04h PSR=%04h MPR=%04h",
                 pc, ir, memory.mem[16'h2000], psr, mpr);
        $display("       expected PC=3002 IR=B002 mem[2000]=0000 PSR[15]=0");
        $fatal(1);
      end

      print_case_pass("mpr_sti_fault");
    end
  endtask

  task automatic run_fetch_fault;
    begin
      memory.mem[16'h2000] = 16'h1265; // ADD R1, R1, #5

      start_case(16'h2000, 1'b1, 16'h0FF8);
      expect_fault_halt("mpr_fetch", 16'h2000, 16'h0000);
    end
  endtask

  task automatic run_load_fault;
    begin
      memory.mem[16'h3000] = 16'h2202; // LD R1, PROTECTED_TARGET_PTR
      memory.mem[16'h3001] = 16'h6040; // LDR R0, R1, #0
      memory.mem[16'h3002] = 16'hD000; // unsupported opcode, should not execute
      memory.mem[16'h3003] = 16'h2000; // PROTECTED_TARGET_PTR in allowed page x3
      memory.mem[16'h2000] = 16'hABCD;

      start_case(16'h3000, 1'b1, 16'h0FF8);
      wait_for_halt("mpr_ldr_fault", 80);

      if (pc !== 16'h3002 ||
          ir !== 16'h6040 ||
          dut.regs[0] !== 16'h0000 ||
          psr[15] !== 1'b0) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "mpr_ldr_fault");
        $display("       actual   PC=%04h IR=%04h R0=%04h PSR=%04h MPR=%04h",
                 pc, ir, dut.regs[0], psr, mpr);
        $display("       expected PC=3002 IR=6040 R0=0000 PSR[15]=0");
        $fatal(1);
      end

      print_case_pass("mpr_ldr_fault");
    end
  endtask

  task automatic run_direct_store_fault;
    begin
      memory.mem[16'h3000] = 16'h2203; // LD R1, PROTECTED_TARGET_PTR
      memory.mem[16'h3001] = 16'h2003; // LD R0, DATA
      memory.mem[16'h3002] = 16'h7040; // STR R0, R1, #0
      memory.mem[16'h3003] = 16'hD000; // unsupported opcode, should not execute
      memory.mem[16'h3004] = 16'h2000; // PROTECTED_TARGET_PTR in allowed page x3
      memory.mem[16'h3005] = 16'h1234; // DATA
      memory.mem[16'h2000] = 16'h0000;

      start_case(16'h3000, 1'b1, 16'h0FF8);
      wait_for_halt("mpr_str_fault", 80);

      if (pc !== 16'h3003 ||
          ir !== 16'h7040 ||
          memory.mem[16'h2000] !== 16'h0000 ||
          psr[15] !== 1'b0) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "mpr_str_fault");
        $display("       actual   PC=%04h IR=%04h mem[2000]=%04h PSR=%04h MPR=%04h",
                 pc, ir, memory.mem[16'h2000], psr, mpr);
        $display("       expected PC=3003 IR=7040 mem[2000]=0000 PSR[15]=0");
        $fatal(1);
      end

      print_case_pass("mpr_str_fault");
    end
  endtask

  task automatic run_allowed_user_access;
    begin
      memory.mem[16'h3000] = 16'h2003; // LD R0, DATA
      memory.mem[16'h3001] = 16'h3003; // ST R0, TARGET
      memory.mem[16'h3002] = 16'h2202; // LD R1, TARGET
      memory.mem[16'h3003] = 16'hD000; // unsupported opcode, used as test halt
      memory.mem[16'h3004] = 16'h1234; // DATA
      memory.mem[16'h3005] = 16'h0000; // TARGET in allowed page x3

      start_case(16'h3000, 1'b1, 16'h0FF8);
      wait_for_halt("mpr_allowed", 80);

      if (pc !== 16'h3004 ||
          ir !== 16'hD000 ||
          dut.regs[0] !== 16'h1234 ||
          dut.regs[1] !== 16'h1234 ||
          memory.mem[16'h3005] !== 16'h1234 ||
          psr[15] !== 1'b0) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "mpr_allowed");
        $display("       actual   PC=%04h IR=%04h R0=%04h R1=%04h mem[3005]=%04h PSR=%04h MPR=%04h",
                 pc, ir, dut.regs[0], dut.regs[1], memory.mem[16'h3005], psr, mpr);
        $display("       expected PC=3004 IR=D000 R0=1234 R1=1234 mem[3005]=1234 PSR[15]=0");
        $fatal(1);
      end

      print_case_pass("mpr_allowed");
    end
  endtask

  task automatic run_supervisor_bypass;
    begin
      memory.mem[16'h3000] = 16'h2203; // LD R1, PROTECTED_TARGET_PTR
      memory.mem[16'h3001] = 16'h2003; // LD R0, DATA
      memory.mem[16'h3002] = 16'h7040; // STR R0, R1, #0
      memory.mem[16'h3003] = 16'hD000; // unsupported opcode, used as test halt
      memory.mem[16'h3004] = 16'h2000; // PROTECTED_TARGET_PTR
      memory.mem[16'h3005] = 16'h1234; // DATA
      memory.mem[16'h2000] = 16'h0000;

      start_case(16'h3000, 1'b0, 16'h0FF8);
      wait_for_halt("mpr_super", 80);

      if (pc !== 16'h3004 ||
          ir !== 16'hD000 ||
          memory.mem[16'h2000] !== 16'h1234 ||
          psr[15] !== 1'b1) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "mpr_super");
        $display("       actual   PC=%04h IR=%04h mem[2000]=%04h PSR=%04h MPR=%04h",
                 pc, ir, memory.mem[16'h2000], psr, mpr);
        $display("       expected PC=3004 IR=D000 mem[2000]=1234 PSR[15]=1");
        $fatal(1);
      end

      print_case_pass("mpr_super");
    end
  endtask

  task automatic run_trap_exemption;
    begin
      memory.mem[16'h0022] = 16'h3100; // TRAP x22 handler
      memory.mem[16'h3000] = 16'hF022; // TRAP x22
      memory.mem[16'h3001] = 16'hD000; // unsupported opcode, used as test halt
      memory.mem[16'h3100] = 16'hC1C1; // RTT R7

      saw_trap_handler = 1'b0;
      start_case(16'h3000, 1'b1, 16'h0FF8);

      for (cycle = 0; cycle < 80; cycle = cycle + 1) begin
        @(posedge clk);

        if (pc == 16'h3101 && ir == 16'hC1C1) begin
          if (psr[15] !== 1'b1 || dut.regs[7] !== 16'h3001) begin
            $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "mpr_trap");
            $display("       actual   PC=%04h IR=%04h R7=%04h PSR=%04h MPR=%04h",
                     pc, ir, dut.regs[7], psr, mpr);
            $display("       expected handler supervisor mode, R7=3001");
            $fatal(1);
          end

          saw_trap_handler = 1'b1;
        end

        if (dut.halted) begin
          cycle = 80;
        end
      end

      if (!dut.halted ||
          !saw_trap_handler ||
          pc !== 16'h3002 ||
          ir !== 16'hD000 ||
          psr[15] !== 1'b0) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, "mpr_trap");
        $display("       actual   halted=%0d saw_handler=%0d PC=%04h IR=%04h PSR=%04h MPR=%04h",
                 dut.halted, saw_trap_handler, pc, ir, psr, mpr);
        $display("       expected halted=1 saw_handler=1 PC=3002 IR=D000 PSR[15]=0");
        $fatal(1);
      end

      print_case_pass("mpr_trap");
    end
  endtask

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_mpr_protection_tb.vcd");
      $dumpvars(0, lc3_mpr_protection_tb);
    end

    reset_pc = 16'h3000;
    mpr = 16'hFFFF;

    run_indirect_store_fault();
    run_fetch_fault();
    run_load_fault();
    run_direct_store_fault();
    run_allowed_user_access();
    run_supervisor_bypass();
    run_trap_exemption();

    $finish;
  end
endmodule
