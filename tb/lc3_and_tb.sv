`timescale 1ns/1ps

module lc3_and_tb;
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
    $readmemh("programs/and/and_smoke.hex", memory.mem);
  end

  initial begin
    $dumpfile("sim/lc3_and_tb.vcd");
    $dumpvars(0, lc3_and_tb);

    saw_halt = 1'b0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 150; cycle = cycle + 1) begin
      @(posedge clk);
      if (dut.halted) begin
        saw_halt = 1'b1;

        if (dut.regs[1] !== 16'h0007 ||
            dut.regs[2] !== 16'h0003 ||
            dut.regs[3] !== 16'h0003 ||
            dut.regs[4] !== 16'h0000 ||
            dut.regs[5] !== 16'h0007 ||
            dut.n !== 1'b0 ||
            dut.z !== 1'b0 ||
            dut.p !== 1'b1) begin
          $display("FAIL and_smoke");
          $display("  regs: R1=x%04h R2=x%04h R3=x%04h R4=x%04h R5=x%04h",
                   dut.regs[1], dut.regs[2], dut.regs[3], dut.regs[4], dut.regs[5]);
          $display("  cc  : N=%0b Z=%0b P=%0b", dut.n, dut.z, dut.p);
          $fatal(1);
        end

        $display("PASS and_smoke");
        $finish;
      end
    end

    if (!saw_halt) begin
      $display("FAIL and_smoke: CPU did not halt");
      $fatal(1);
    end
  end
endmodule
